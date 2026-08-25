#!/usr/bin/env node
/**
 * FTL 小票自测入口。
 *
 * 用法：
 *   node ftl-selftest/run-selftest.mjs <模版.ftl> <数据.json> [报告输出路径]
 *
 * 做四件事：
 *   1. 指令闭合检查
 *   2. 分支覆盖统计（顶层分支直接判定，循环内分支逐数据行判定）
 *   3. 空值与数组越界风险（按实际数据逐行验证，并扣除被上层 #if 挡住的行）
 *   4. 模版与 JSON 的字段对账
 *
 * 产出：控制台摘要 + 同目录 `<模版名>.selftest.md` 报告。
 * 退出码：0 = 无错误级问题，1 = 存在错误级问题（可接 CI）。
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  blankComments,
  scanDirectives,
  scanInterpolations,
  parseAssign,
  parseList,
  parseFunction,
} from './ftl-scanner.mjs';
import {
  evaluateCondition,
  evaluateValue,
  resolvePath,
  TRUE,
  FALSE,
  UNKNOWN,
} from './condition-evaluator.mjs';

const SEVERITY_ERROR = '错误';
const SEVERITY_WARN = '告警';

const SCOPE_DATA = 'data';
const SCOPE_LOOP = 'loop';
const SCOPE_FUNCTION = 'function';

/** 需要配对闭合的块级指令 */
const BLOCK_DIRECTIVES = new Set([
  'if',
  'list',
  'function',
  'macro',
  'switch',
  'attempt',
  'compress',
  'escape',
  'noparse',
]);

/** FreeMarker 内建与关键字，做字段对账时要排除 */
const FREEMARKER_KEYWORDS = new Set([
  'true', 'false', 'as', 'gt', 'gte', 'lt', 'lte', 'in', 'using',
  'size', 'has_content', 'is_string', 'is_number', 'is_hash', 'is_sequence',
  'is_boolean', 'string', 'number', 'trim', 'length', 'lower_case', 'upper_case',
  'starts_with', 'ends_with', 'contains', 'round', 'then', 'c', 'js_string',
  'html', 'xml', 'default', 'first', 'last', 'seq_contains', 'keys', 'values',
  'index', 'counter', 'item_parity', 'split', 'replace', 'substring',
]);

/**
 * 抽出可用作分区名的注释。
 * 紧跟 #function / #assign 的注释是在解释某段实现，不是分区标题，要排除，
 * 否则后面的分支会被贴上一个毫不相干的分区名。
 */
function scanComments(source) {
  const sourceLines = source.split('\n');
  const comments = [];
  const commentPattern = /<#--([\s\S]*?)-->/g;
  let match = commentPattern.exec(source);

  while (match !== null) {
    const startLine = source.slice(0, match.index).split('\n').length;
    const endLine = startLine + match[0].split('\n').length - 1;

    let nextCodeLine = '';
    for (let lineIndex = endLine; lineIndex < sourceLines.length; lineIndex += 1) {
      const candidate = sourceLines[lineIndex].trim();
      if (candidate) {
        nextCodeLine = candidate;
        break;
      }
    }
    if (!/^<#(function|macro|assign|local)\b/.test(nextCodeLine)) {
      comments.push({ text: match[1].trim(), line: startLine });
    }
    match = commentPattern.exec(source);
  }
  return comments;
}

function findSectionLabel(comments, line) {
  let label = '';
  for (const comment of comments) {
    if (comment.line <= line) {
      label = comment.text;
    } else {
      break;
    }
  }
  return label.length > 26 ? `${label.slice(0, 26)}…` : label;
}

/** 判断表达式里是否写了 `!默认值`（排除 != 与引号内的感叹号） */
function hasDefaultOperator(expression) {
  let quoteChar = null;
  for (let offset = 0; offset < expression.length; offset += 1) {
    const currentChar = expression[offset];
    if (quoteChar) {
      if (currentChar === quoteChar && expression[offset - 1] !== '\\') quoteChar = null;
      continue;
    }
    if (currentChar === '"' || currentChar === "'") {
      quoteChar = currentChar;
    } else if (currentChar === '!' && expression[offset + 1] !== '=') {
      return true;
    }
  }
  return false;
}

/** 取表达式的根变量名 */
function extractRootName(expression) {
  const rootMatch = expression.trim().match(/^([A-Za-z_]\w*)/);
  return rootMatch ? rootMatch[1] : null;
}

/**
 * 只取路径开头的标识符。
 * 前面是 `.` 或 `?` 的是属性名和内建函数，引号里的是字符串字面量，都不算数据模型字段。
 */
function extractRootNames(text) {
  const withoutStringLiterals = text.replace(/"[^"]*"/g, '""').replace(/'[^']*'/g, "''");
  const rootNames = [];
  for (const match of withoutStringLiterals.matchAll(/(^|[^\w.?])([A-Za-z_]\w*)/g)) {
    rootNames.push(match[2]);
  }
  return rootNames;
}

/** 按路径逐段取值，取不到返回 undefined */
function navigate(value, path) {
  if (!path) return value;
  let current = value;
  for (const segment of path.split('.')) {
    const propertyName = segment.replace(/\[.*$/, '');
    if (current === null || typeof current !== 'object' || !(propertyName in current)) {
      return undefined;
    }
    current = current[propertyName];
    for (const indexMatch of segment.matchAll(/\[(\d+)\]/g)) {
      const arrayIndex = Number(indexMatch[1]);
      if (!Array.isArray(current) || arrayIndex >= current.length) return undefined;
      current = current[arrayIndex];
    }
  }
  return current;
}

/**
 * 枚举某个循环变量的所有取值组合，嵌套循环会连带上层变量一起绑定。
 * 例如 modifierItem 的每组绑定里同时含有它所属的 mealItem，
 * 这样 `contentSize gte 3` 这种引用外层变量的条件也能算准。
 */
function collectBindings(loopVariable, loopSourceMap, dataRoot, visited = new Set()) {
  if (visited.has(loopVariable)) return [];
  visited.add(loopVariable);

  const sourceExpression = loopSourceMap.get(loopVariable);
  if (!sourceExpression) return [];

  const rootName = sourceExpression.split('.')[0].replace(/\[.*$/, '');

  if (loopSourceMap.has(rootName)) {
    const parentBindings = collectBindings(rootName, loopSourceMap, dataRoot, visited);
    const subPath = sourceExpression.slice(rootName.length + 1);
    const bindings = [];
    for (const parentBinding of parentBindings) {
      const childCollection = navigate(parentBinding.get(rootName), subPath);
      if (!Array.isArray(childCollection)) continue;
      for (const childItem of childCollection) {
        const binding = new Map(parentBinding);
        binding.set(loopVariable, childItem);
        bindings.push(binding);
      }
    }
    return bindings;
  }

  const resolved = resolvePath(sourceExpression, {
    dataRoot,
    loopVariables: new Set(),
    localNames: new Set(),
    assignValues: new Map(),
  });
  if (resolved.status !== 'resolved' || !Array.isArray(resolved.value)) return [];
  return resolved.value.map((item) => new Map([[loopVariable, item]]));
}

/** 把条件链（含取反标记）合成一个三态结果 */
function evaluateConditionChain(conditionChain, environment) {
  let state = TRUE;
  for (const link of conditionChain) {
    let linkState = evaluateCondition(link.condition, environment);
    if (link.negated) {
      linkState = linkState === TRUE ? FALSE : linkState === FALSE ? TRUE : UNKNOWN;
    }
    if (linkState === FALSE) return FALSE;
    if (linkState === UNKNOWN) state = UNKNOWN;
  }
  return state;
}

/**
 * 单次顺序遍历：完成指令配对、assign 求值、分支登记、插值上下文采集。
 * 指令和插值按源码偏移合并排序，保证插值能拿到正确的所在分支与循环。
 */
function walkTemplate(directives, interpolations, environment, comments) {
  const events = [
    ...directives.map((item) => ({ kind: 'directive', ...item })),
    ...interpolations.map((item) => ({ kind: 'interpolation', ...item })),
  ].sort((left, right) => left.offset - right.offset);

  const blockStack = [];
  const unmatchedClosings = [];
  const branches = [];
  // 插值和 #assign 右侧都会在运行时求值，空值检查要一视同仁
  const expressionSites = [];
  const loopSourceMap = new Map();
  const allLoopVariables = new Set();
  const allLocalNames = new Set();
  const allAssignExpressions = [];
  const scopedAssigns = [];
  const globalAssignNames = new Set();

  const activeLoopVariables = () =>
    blockStack.filter((block) => block.name === 'list' && block.itemVariable)
      .map((block) => block.itemVariable);

  const insideFunction = () =>
    blockStack.some((block) => block.name === 'function' || block.name === 'macro');

  /** 把所有外层 #if 的条件链拼起来，用于判断某处代码在什么前提下才会执行 */
  const enclosingConditionChain = () => {
    const chain = [];
    for (const block of blockStack) {
      if (block.name === 'if' && block.activeChain) chain.push(...block.activeChain);
    }
    return chain;
  };

  for (const event of events) {
    if (event.kind === 'interpolation') {
      const loopVariables = activeLoopVariables();
      expressionSites.push({
        kind: '插值',
        expression: event.expression,
        line: event.line,
        offset: event.offset,
        innermostLoopVariable: loopVariables[loopVariables.length - 1] || null,
        conditionChain: enclosingConditionChain(),
        insideFunction: insideFunction(),
      });
      continue;
    }

    if (event.isClosing) {
      if (BLOCK_DIRECTIVES.has(event.name)) {
        const topBlock = blockStack[blockStack.length - 1];
        if (!topBlock || topBlock.name !== event.name) {
          unmatchedClosings.push(event);
        } else {
          blockStack.pop();
          if (event.name === 'list' && topBlock.itemVariable) {
            environment.loopVariables.delete(topBlock.itemVariable);
          }
          if (
            (event.name === 'function' || event.name === 'macro') &&
            topBlock.parameterNames
          ) {
            for (const parameterName of topBlock.parameterNames) {
              environment.localNames.delete(parameterName);
            }
          }
        }
      }
      continue;
    }

    switch (event.name) {
      case 'if': {
        const activeChain = [{ condition: event.params, negated: false }];
        const state = evaluateConditionChain(
          [...enclosingConditionChain(), ...activeChain],
          environment
        );
        const loopVariables = activeLoopVariables();
        branches.push({
          condition: event.params,
          line: event.line,
          section: findSectionLabel(comments, event.line),
          scope: insideFunction()
            ? SCOPE_FUNCTION
            : loopVariables.length > 0
              ? SCOPE_LOOP
              : SCOPE_DATA,
          innermostLoopVariable: loopVariables[loopVariables.length - 1] || null,
          conditionChain: [...enclosingConditionChain(), ...activeChain],
          offset: event.offset,
          state,
        });
        blockStack.push({
          name: 'if',
          seenConditions: [event.params],
          activeChain,
          line: event.line,
        });
        break;
      }
      case 'elseif': {
        const topBlock = blockStack[blockStack.length - 1];
        if (topBlock && topBlock.name === 'if') {
          topBlock.seenConditions.push(event.params);
          topBlock.activeChain = [
            ...topBlock.seenConditions
              .slice(0, -1)
              .map((condition) => ({ condition, negated: true })),
            { condition: event.params, negated: false },
          ];
          const loopVariables = activeLoopVariables();
          branches.push({
            condition: event.params,
            line: event.line,
            section: findSectionLabel(comments, event.line),
            scope: insideFunction()
              ? SCOPE_FUNCTION
              : loopVariables.length > 0
                ? SCOPE_LOOP
                : SCOPE_DATA,
            innermostLoopVariable: loopVariables[loopVariables.length - 1] || null,
            conditionChain: enclosingConditionChain(),
            offset: event.offset,
            state: evaluateConditionChain(enclosingConditionChain(), environment),
          });
        }
        break;
      }
      case 'else': {
        const topBlock = blockStack[blockStack.length - 1];
        if (topBlock && topBlock.name === 'if') {
          topBlock.activeChain = topBlock.seenConditions.map((condition) => ({
            condition,
            negated: true,
          }));
        }
        break;
      }
      case 'list': {
        const listInfo = parseList(event.params);
        if (listInfo) {
          environment.loopVariables.add(listInfo.itemVariable);
          allLoopVariables.add(listInfo.itemVariable);
          loopSourceMap.set(listInfo.itemVariable, listInfo.sourceExpression);
          blockStack.push({ name: 'list', itemVariable: listInfo.itemVariable, line: event.line });
        } else {
          blockStack.push({ name: 'list', line: event.line });
        }
        break;
      }
      case 'function':
      case 'macro': {
        const functionInfo = parseFunction(event.params);
        if (functionInfo) {
          environment.functionNames.add(functionInfo.functionName);
          for (const parameterName of functionInfo.parameterNames) {
            environment.localNames.add(parameterName);
            allLocalNames.add(parameterName);
          }
          blockStack.push({
            name: event.name,
            parameterNames: functionInfo.parameterNames,
            line: event.line,
          });
        } else {
          blockStack.push({ name: event.name, line: event.line });
        }
        break;
      }
      case 'assign':
      case 'local': {
        const assignInfo = parseAssign(event.params);
        if (!assignInfo) break;
        allAssignExpressions.push(assignInfo.expression);
        const assignLoopVariables = activeLoopVariables();
        expressionSites.push({
          kind: '赋值',
          expression: assignInfo.expression,
          line: event.line,
          offset: event.offset,
          innermostLoopVariable: assignLoopVariables[assignLoopVariables.length - 1] || null,
          conditionChain: enclosingConditionChain(),
          insideFunction: insideFunction(),
        });
        const isScoped = assignLoopVariables.length > 0 || insideFunction();
        if (isScoped) {
          // 循环内的赋值依赖具体数据行，留到逐元素阶段再算
          scopedAssigns.push({ ...assignInfo, offset: event.offset });
          environment.assignValues.set(assignInfo.variableName, { state: UNKNOWN });
          break;
        }
        globalAssignNames.add(assignInfo.variableName);
        const branchState = evaluateConditionChain(enclosingConditionChain(), environment);
        if (branchState === FALSE) break; // 该赋值不会执行，保持原值
        const evaluated = evaluateValue(assignInfo.expression, environment);
        if (branchState === UNKNOWN || evaluated.status === UNKNOWN) {
          environment.assignValues.set(assignInfo.variableName, { state: UNKNOWN });
        } else {
          environment.assignValues.set(assignInfo.variableName, {
            state: 'resolved',
            value: evaluated.value,
          });
        }
        break;
      }
      default:
        if (BLOCK_DIRECTIVES.has(event.name)) {
          blockStack.push({ name: event.name, line: event.line });
        }
    }
  }

  return {
    branches,
    expressionSites,
    loopSourceMap,
    allLoopVariables,
    allLocalNames,
    allAssignExpressions,
    scopedAssigns,
    globalAssignNames,
    blockStack,
    unmatchedClosings,
  };
}

/** 为逐元素求值构造环境：绑定数据行 + 重放该位置之前的循环内赋值 */
function buildElementEnvironment(binding, walkResult, environment, beforeOffset) {
  const assignValues = new Map();
  for (const name of walkResult.globalAssignNames) {
    if (environment.assignValues.has(name)) {
      assignValues.set(name, environment.assignValues.get(name));
    }
  }

  const elementEnvironment = {
    dataRoot: environment.dataRoot,
    loopVariables: walkResult.allLoopVariables,
    localNames: environment.localNames,
    functionNames: environment.functionNames,
    assignValues,
    elementScope: binding,
  };

  for (const scopedAssign of walkResult.scopedAssigns) {
    if (scopedAssign.offset >= beforeOffset) break;
    const evaluated = evaluateValue(scopedAssign.expression, elementEnvironment);
    assignValues.set(
      scopedAssign.variableName,
      evaluated.status === 'resolved'
        ? { state: 'resolved', value: evaluated.value }
        : { state: UNKNOWN }
    );
  }
  return elementEnvironment;
}

/** 逐数据行统计循环内分支的真假分布 */
function evaluateLoopBranches(walkResult, environment, dataRoot) {
  const bindingCache = new Map();

  for (const branch of walkResult.branches) {
    if (branch.scope !== SCOPE_LOOP || !branch.innermostLoopVariable) continue;

    if (!bindingCache.has(branch.innermostLoopVariable)) {
      bindingCache.set(
        branch.innermostLoopVariable,
        collectBindings(branch.innermostLoopVariable, walkResult.loopSourceMap, dataRoot)
      );
    }
    const bindings = bindingCache.get(branch.innermostLoopVariable);
    const tally = { true: 0, false: 0, unknown: 0 };

    for (const binding of bindings) {
      const elementEnvironment = buildElementEnvironment(
        binding,
        walkResult,
        environment,
        branch.offset
      );
      const state = evaluateConditionChain(branch.conditionChain, elementEnvironment);
      tally[state] += 1;
    }

    branch.elementTally = tally;
    branch.elementTotal = bindings.length;
    if (bindings.length > 0 && tally.unknown === 0) {
      branch.state = tally.true > 0 ? TRUE : FALSE;
    }
  }
}

function runChecks(walkResult, environment, dataRoot) {
  const findings = [];
  const { expressionSites, loopSourceMap, blockStack, unmatchedClosings } = walkResult;
  const scopedAssignNames = new Set(walkResult.scopedAssigns.map((item) => item.variableName));
  const describeSite = (site) =>
    site.kind === '插值' ? `\`\${${site.expression}}\`` : `赋值表达式 \`${site.expression}\``;

  // 检查一：指令闭合
  for (const openBlock of blockStack) {
    findings.push({
      severity: SEVERITY_ERROR,
      category: '指令闭合',
      line: openBlock.line,
      message: `\`<#${openBlock.name}>\` 没有找到配对的 \`</#${openBlock.name}>\``,
    });
  }
  for (const closing of unmatchedClosings) {
    findings.push({
      severity: SEVERITY_ERROR,
      category: '指令闭合',
      line: closing.line,
      message: `多余的 \`</#${closing.name}>\`，找不到对应的开始标签`,
    });
  }

  // 检查二 & 三：空值与数组越界，按实际数据逐行验证
  const bindingCache = new Map();
  for (const context of expressionSites) {
    // 写了 `!默认值` 或用 `??` 做过存在性判断的，运行时不会抛错
    if (
      hasDefaultOperator(context.expression) ||
      context.expression.includes('??') ||
      context.insideFunction
    ) {
      continue;
    }

    const rootName = extractRootName(context.expression);
    if (!rootName) continue;
    if (
      FREEMARKER_KEYWORDS.has(rootName) ||
      environment.functionNames.has(rootName) ||
      walkResult.allLocalNames.has(rootName) ||
      walkResult.globalAssignNames.has(rootName) ||
      scopedAssignNames.has(rootName)
    ) {
      continue;
    }
    const pathOnly = context.expression.split(/[?(]/)[0].trim();
    const isIndexed = /\[\d+\]/.test(pathOnly);

    // 循环变量：逐数据行验证，并扣掉被上层 #if 挡住的行
    if (loopSourceMap.has(rootName)) {
      if (!bindingCache.has(rootName)) {
        bindingCache.set(rootName, collectBindings(rootName, loopSourceMap, dataRoot));
      }
      const bindings = bindingCache.get(rootName);
      if (bindings.length === 0) continue;

      let reachableCount = 0;
      let missingCount = 0;
      let undecidedCount = 0;
      for (const binding of bindings) {
        const elementEnvironment = buildElementEnvironment(
          binding,
          walkResult,
          environment,
          context.offset
        );
        const reachState = evaluateConditionChain(context.conditionChain, elementEnvironment);
        if (reachState === FALSE) continue;
        if (reachState === UNKNOWN) undecidedCount += 1;
        reachableCount += 1;
        if (resolvePath(pathOnly, elementEnvironment).status === 'missing') {
          missingCount += 1;
        }
      }

      if (missingCount > 0) {
        findings.push({
          severity: undecidedCount > 0 ? SEVERITY_WARN : SEVERITY_ERROR,
          category: isIndexed ? '数组越界' : '空值风险',
          line: context.line,
          message:
            `${describeSite(context)} 未写 \`!默认值\`；` +
            `会执行到这行的 ${reachableCount} 条数据里有 ${missingCount} 条取不到值，渲染会抛 InvalidReferenceException` +
            (undecidedCount > 0 ? `（其中 ${undecidedCount} 条的可达性判不了，需人工确认）` : ''),
        });
      }
      continue;
    }

    // 数据模型路径：直接解析
    const resolved = resolvePath(pathOnly, environment);
    if (resolved.status === 'missing') {
      const reachState = evaluateConditionChain(context.conditionChain, environment);
      if (reachState === FALSE) continue;
      findings.push({
        severity: reachState === UNKNOWN ? SEVERITY_WARN : SEVERITY_ERROR,
        category: '空值风险',
        line: context.line,
        message: `${describeSite(context)} 在数据中取不到，且没写 \`!默认值\`，渲染会抛 InvalidReferenceException`,
      });
    }
  }

  // 检查四：字段对账
  const referencedRoots = new Set();
  const referenceSources = [
    ...expressionSites.map((site) => site.expression),
    ...walkResult.branches.map((branch) => branch.condition),
    // #assign 右侧同样是对数据模型的引用，漏扫会把用到的字段误判成「未使用」
    ...walkResult.allAssignExpressions,
    ...walkResult.loopSourceMap.values(),
  ];
  for (const sourceText of referenceSources) {
    for (const name of extractRootNames(sourceText)) referencedRoots.add(name);
  }

  const dataRootKeys = new Set(Object.keys(dataRoot));
  const isTemplateLocal = (name) =>
    walkResult.allLoopVariables.has(name) ||
    walkResult.globalAssignNames.has(name) ||
    environment.functionNames.has(name) ||
    walkResult.allLocalNames.has(name) ||
    walkResult.scopedAssigns.some((item) => item.variableName === name) ||
    FREEMARKER_KEYWORDS.has(name);

  const templateOnlyRoots = [...referencedRoots].filter(
    (name) => !dataRootKeys.has(name) && !isTemplateLocal(name)
  );
  const unusedDataKeys = [...dataRootKeys].filter(
    (name) => !referencedRoots.has(name) && !name.startsWith('_')
  );

  return { findings, templateOnlyRoots, unusedDataKeys };
}

function formatBranchRow(branch) {
  const conditionText = branch.condition.replace(/\s+/g, ' ');
  const shortCondition =
    conditionText.length > 52 ? `${conditionText.slice(0, 52)}…` : conditionText;

  if (branch.scope === SCOPE_LOOP) {
    if (!branch.elementTotal) {
      return `| ${branch.line} | ${branch.section || '-'} | \`${shortCondition}\` | 无数据行 | 外层循环在本次数据里就是空的，整段没测到 |`;
    }
    const { true: trueCount, false: falseCount, unknown: unknownCount } = branch.elementTally;
    const detail =
      `${branch.elementTotal} 行中 ${trueCount} 真 / ${falseCount} 假` +
      (unknownCount > 0 ? ` / ${unknownCount} 判不了` : '');
    let todo;
    if (unknownCount > 0) {
      todo = `${unknownCount} 行判不了，需人工确认`;
    } else if (trueCount === 0) {
      todo = '当前数据从未走进，需补数据';
    } else if (falseCount === 0) {
      todo = '当前数据全部走进，需补反例';
    } else {
      todo = '两侧都已覆盖';
    }
    return `| ${branch.line} | ${branch.section || '-'} | \`${shortCondition}\` | ${detail} | ${todo} |`;
  }

  const hitLabel = branch.state === TRUE ? '真' : branch.state === FALSE ? '假' : '判不了';
  const todoLabel =
    branch.state === TRUE
      ? '补一组让条件为假的数据'
      : branch.state === FALSE
        ? '补一组让条件为真的数据'
        : '需人工确认';
  return `| ${branch.line} | ${branch.section || '-'} | \`${shortCondition}\` | ${hitLabel} | ${todoLabel} |`;
}

function buildReport(options) {
  const { templateFileName, dataFileName, branches, findings, templateOnlyRoots, unusedDataKeys } =
    options;

  const dataBranches = branches.filter((branch) => branch.scope === SCOPE_DATA);
  const loopBranches = branches.filter((branch) => branch.scope === SCOPE_LOOP);
  const functionBranches = branches.filter((branch) => branch.scope === SCOPE_FUNCTION);

  const coveredDataBranches = dataBranches.filter((branch) => branch.state === TRUE);
  const uncoveredDataBranches = dataBranches.filter((branch) => branch.state === FALSE);
  const undecidedDataBranches = dataBranches.filter((branch) => branch.state === UNKNOWN);
  const coverageRate = dataBranches.length
    ? Math.round((coveredDataBranches.length / dataBranches.length) * 100)
    : 0;

  const fullyCoveredLoopBranches = loopBranches.filter(
    (branch) => branch.elementTally && branch.elementTally.true > 0 && branch.elementTally.false > 0
  );

  const errorCount = findings.filter((item) => item.severity === SEVERITY_ERROR).length;
  const warnCount = findings.filter((item) => item.severity === SEVERITY_WARN).length;
  const conclusion = errorCount > 0 ? '不通过' : warnCount > 0 ? '通过（有告警需确认）' : '通过';

  const lines = [];
  lines.push(`# FTL 自测报告 · ${templateFileName}`);
  lines.push('');
  lines.push(`> 数据：\`${dataFileName}\``);
  lines.push(`> 生成：${new Date().toLocaleString('zh-CN', { hour12: false })}`);
  lines.push('> 工具：ftl-selftest（静态分析 + 逐数据行推演，非 FreeMarker 引擎渲染）');
  lines.push('');

  lines.push('## 结论');
  lines.push('');
  lines.push(`**${conclusion}** — 错误 ${errorCount} 项，告警 ${warnCount} 项。`);
  lines.push('');
  lines.push(
    `顶层分区覆盖 ${coveredDataBranches.length}/${dataBranches.length}（${coverageRate}%）：` +
      `本次数据未走到 ${uncoveredDataBranches.length} 个，${undecidedDataBranches.length} 个判不了。`
  );
  lines.push('');
  lines.push(
    `循环内分支 ${loopBranches.length} 个，其中 ${fullyCoveredLoopBranches.length} 个在本次数据里真假两侧都出现过。`
  );
  lines.push('');

  lines.push('## 一、问题清单');
  lines.push('');
  if (findings.length === 0) {
    lines.push('未发现问题。');
  } else {
    lines.push('| 级别 | 类别 | 行号 | 说明 |');
    lines.push('|------|------|------|------|');
    const severityOrder = { [SEVERITY_ERROR]: 0, [SEVERITY_WARN]: 1 };
    const sortedFindings = [...findings].sort(
      (left, right) =>
        severityOrder[left.severity] - severityOrder[right.severity] || left.line - right.line
    );
    for (const finding of sortedFindings) {
      lines.push(`| ${finding.severity} | ${finding.category} | ${finding.line} | ${finding.message} |`);
    }
  }
  lines.push('');

  lines.push('## 二、顶层分区用例矩阵');
  lines.push('');
  lines.push('这些分支决定「哪些区块整块显示或隐藏」，是最需要造数据覆盖的部分。');
  lines.push('');
  lines.push('| 行号 | 所属分区 | 条件 | 本次命中 | 待补用例 |');
  lines.push('|------|----------|------|----------|----------|');
  for (const branch of dataBranches) {
    lines.push(formatBranchRow(branch));
  }
  lines.push('');

  lines.push('## 三、循环内分支（逐数据行统计）');
  lines.push('');
  lines.push('每一行统计的是「该条件在实际数据的每一条记录上分别取什么值」。');
  lines.push('');
  lines.push('| 行号 | 所属分区 | 条件 | 数据行分布 | 覆盖情况 |');
  lines.push('|------|----------|------|------------|----------|');
  for (const branch of loopBranches) {
    lines.push(formatBranchRow(branch));
  }
  lines.push('');

  if (functionBranches.length > 0) {
    lines.push('## 四、函数内分支（由入参决定，静态判不了）');
    lines.push('');
    lines.push('| 行号 | 条件 |');
    lines.push('|------|------|');
    for (const branch of functionBranches) {
      lines.push(`| ${branch.line} | \`${branch.condition.replace(/\s+/g, ' ')}\` |`);
    }
    lines.push('');
  }

  lines.push('## 五、字段对账');
  lines.push('');
  lines.push('**模版引用了、但 JSON 顶层没有的字段：**');
  lines.push('');
  if (templateOnlyRoots.length === 0) {
    lines.push('无。');
  } else {
    for (const name of templateOnlyRoots) {
      lines.push(`- \`${name}\` — 后端若不下发，相关分支恒为假，需确认是否符合预期`);
    }
  }
  lines.push('');
  lines.push('**JSON 里有、但模版没用到的字段：**');
  lines.push('');
  if (unusedDataKeys.length === 0) {
    lines.push('无。');
  } else {
    for (const name of unusedDataKeys) {
      lines.push(`- \`${name}\``);
    }
  }
  lines.push('');

  lines.push('## 六、本报告测不到的部分');
  lines.push('');
  lines.push('以下必须人工或真机验证：');
  lines.push('');
  lines.push('- 真实 FreeMarker 引擎的渲染结果（本工具只做静态推演）');
  lines.push('- 视觉样式：断行、对齐、溢出、弹层位置');
  lines.push('- 邮件客户端兼容性（Outlook / Gmail 会改写或剥离 CSS）');
  lines.push('- 短信通道与短链跳转');
  lines.push('- 业务口径是否符合产品预期');
  lines.push('');

  return { content: lines.join('\n'), errorCount, warnCount, conclusion, coverageRate };
}

/** 对外分析入口：给一份模版源码和一份数据，返回全部分析结果 */
export function analyzeTemplate(rawSource, dataRoot) {
  const comments = scanComments(rawSource);
  const cleanSource = blankComments(rawSource);
  const directives = scanDirectives(cleanSource);
  const interpolations = scanInterpolations(cleanSource);

  const environment = {
    dataRoot,
    loopVariables: new Set(),
    localNames: new Set(),
    functionNames: new Set(),
    assignValues: new Map(),
  };

  const walkResult = walkTemplate(directives, interpolations, environment, comments);
  evaluateLoopBranches(walkResult, environment, dataRoot);
  const { findings, templateOnlyRoots, unusedDataKeys } = runChecks(
    walkResult,
    environment,
    dataRoot
  );

  return {
    directiveCount: directives.length,
    interpolationCount: interpolations.length,
    branches: walkResult.branches,
    findings,
    templateOnlyRoots,
    unusedDataKeys,
  };
}

export { SEVERITY_ERROR, SEVERITY_WARN, SCOPE_DATA, SCOPE_LOOP };

function main() {
  const [templatePath, dataPath, reportPathArgument] = process.argv.slice(2);
  if (!templatePath || !dataPath) {
    console.error('用法：node ftl-selftest/run-selftest.mjs <模版.ftl> <数据.json> [报告输出路径]');
    process.exit(1);
  }

  const rawSource = readFileSync(templatePath, 'utf8');
  const dataRoot = JSON.parse(readFileSync(dataPath, 'utf8'));
  const analysis = analyzeTemplate(rawSource, dataRoot);
  const { directiveCount, interpolationCount, branches, findings, templateOnlyRoots, unusedDataKeys } =
    analysis;

  const templateFileName = basename(templatePath);
  const report = buildReport({
    templateFileName,
    dataFileName: basename(dataPath),
    branches,
    findings,
    templateOnlyRoots,
    unusedDataKeys,
  });

  const reportPath =
    reportPathArgument ||
    join(dirname(templatePath), `${templateFileName.replace(/\.ftl$/, '')}.selftest.md`);
  writeFileSync(reportPath, report.content, 'utf8');

  console.log(`模版：${templateFileName}`);
  console.log(
    `指令 ${directiveCount} 条，插值 ${interpolationCount} 处，分支 ${branches.length} 个`
  );
  console.log(`顶层分区覆盖：${report.coverageRate}%`);
  console.log(`结论：${report.conclusion}（错误 ${report.errorCount}，告警 ${report.warnCount}）`);
  console.log(`报告：${reportPath}`);

  process.exit(report.errorCount > 0 ? 1 : 0);
}

// 被 run-suite 引入时不执行 CLI 逻辑
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
