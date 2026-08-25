#!/usr/bin/env node
/**
 * 场景套件批量自测。
 *
 * 用法：
 *   node ftl-selftest/run-suite.mjs <模版.ftl> [场景定义.json]
 *
 * 按 scenarios.json 里的增删改规则，从一份 base 数据派生出多组场景数据，
 * 逐个跑分析，汇总成一张「场景 × 结论」的表。
 *
 * 退出码：0 = 全部场景无错误，1 = 至少一个场景有错误。
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { analyzeTemplate, SEVERITY_ERROR, SCOPE_DATA } from './run-selftest.mjs';
import { TRUE, UNKNOWN } from './condition-evaluator.mjs';

/** 把 `a.b[0].c` 拆成可逐级下钻的片段 */
function splitPath(pathText) {
  const segments = [];
  for (const rawSegment of pathText.split('.')) {
    const propertyName = rawSegment.replace(/\[.*$/, '');
    if (propertyName) segments.push({ type: 'key', value: propertyName });
    for (const indexMatch of rawSegment.matchAll(/\[(\d+)\]/g)) {
      segments.push({ type: 'index', value: Number(indexMatch[1]) });
    }
  }
  return segments;
}

function removePath(dataRoot, pathText) {
  const segments = splitPath(pathText);
  let current = dataRoot;
  for (let position = 0; position < segments.length - 1; position += 1) {
    const segment = segments[position];
    if (current === null || typeof current !== 'object') return;
    current = current[segment.value];
  }
  const lastSegment = segments[segments.length - 1];
  if (current === null || typeof current !== 'object') return;
  if (lastSegment.type === 'index' && Array.isArray(current)) {
    current.splice(lastSegment.value, 1);
  } else {
    delete current[lastSegment.value];
  }
}

function setPath(dataRoot, pathText, value) {
  const segments = splitPath(pathText);
  let current = dataRoot;
  for (let position = 0; position < segments.length - 1; position += 1) {
    const segment = segments[position];
    // 中间层不存在时按下一段的类型补建，避免写入失败
    if (current[segment.value] === undefined || current[segment.value] === null) {
      current[segment.value] = segments[position + 1].type === 'index' ? [] : {};
    }
    current = current[segment.value];
  }
  current[segments[segments.length - 1].value] = value;
}

function buildScenarioData(baseData, scenario) {
  const scenarioData = structuredClone(baseData);
  for (const pathText of scenario.remove || []) {
    removePath(scenarioData, pathText);
  }
  for (const [pathText, value] of Object.entries(scenario.set || {})) {
    setPath(scenarioData, pathText, value);
  }
  return scenarioData;
}

function main() {
  const [templatePath, scenarioPathArgument] = process.argv.slice(2);
  if (!templatePath) {
    console.error('用法：node ftl-selftest/run-suite.mjs <模版.ftl> [场景定义.json]');
    process.exit(1);
  }

  // 中文路径要用 fileURLToPath 还原，直接取 URL.pathname 会拿到百分号编码
  const scenarioPath = resolve(
    scenarioPathArgument || fileURLToPath(new URL('./scenarios.json', import.meta.url))
  );
  const scenarioConfig = JSON.parse(readFileSync(scenarioPath, 'utf8'));
  const basePath = resolve(dirname(scenarioPath), scenarioConfig.base);
  const baseData = JSON.parse(readFileSync(basePath, 'utf8'));
  const rawSource = readFileSync(templatePath, 'utf8');

  const results = [];
  for (const scenario of scenarioConfig.scenarios) {
    const scenarioData = buildScenarioData(baseData, scenario);
    const analysis = analyzeTemplate(rawSource, scenarioData);

    const errorCount = analysis.findings.filter((item) => item.severity === SEVERITY_ERROR).length;
    const warnCount = analysis.findings.length - errorCount;
    const dataBranches = analysis.branches.filter((branch) => branch.scope === SCOPE_DATA);
    const coveredBranches = dataBranches.filter((branch) => branch.state === TRUE);
    const decidableBranches = dataBranches.filter((branch) => branch.state !== UNKNOWN);

    results.push({
      name: scenario.name,
      expect: scenario.expect,
      errorCount,
      warnCount,
      findings: analysis.findings,
      coverage: decidableBranches.length
        ? Math.round((coveredBranches.length / decidableBranches.length) * 100)
        : 0,
      branchStates: new Map(dataBranches.map((branch) => [branch.line, branch.state])),
      dataBranches,
    });
  }

  const allDataBranches = results[0] ? results[0].dataBranches : [];

  /**
   * 合并统计要区分两件事：
   *   「从来没为真」= 用例还缺，补数据就能覆盖
   *   「所有场景都判不了」= 条件依赖自定义函数结果，静态分析本来就测不到
   * 混在一起会让人以为是用例没写够，实际是工具能力边界。
   */
  const coveredLines = new Set();
  const undecidableLines = new Set();
  for (const branch of allDataBranches) {
    const statesAcrossScenarios = results.map((result) => result.branchStates.get(branch.line));
    if (statesAcrossScenarios.includes(TRUE)) {
      coveredLines.add(branch.line);
    } else if (statesAcrossScenarios.every((state) => state === UNKNOWN)) {
      undecidableLines.add(branch.line);
    }
  }
  const decidableTotal = allDataBranches.length - undecidableLines.size;
  const suiteCoverage = decidableTotal ? Math.round((coveredLines.size / decidableTotal) * 100) : 0;

  const totalErrors = results.reduce((sum, result) => sum + result.errorCount, 0);
  const totalWarns = results.reduce((sum, result) => sum + result.warnCount, 0);

  const lines = [];
  lines.push(`# FTL 场景套件自测报告 · ${basename(templatePath)}`);
  lines.push('');
  lines.push(`> 基线数据：\`${basename(basePath)}\``);
  lines.push(`> 场景定义：\`${basename(scenarioPath)}\``);
  lines.push(`> 生成：${new Date().toLocaleString('zh-CN', { hour12: false })}`);
  lines.push('');
  lines.push('## 结论');
  lines.push('');
  lines.push(
    `${results.length} 个场景，累计错误 ${totalErrors} 项、告警 ${totalWarns} 项；` +
      `可判定的顶层分区合并覆盖 ${coveredLines.size}/${decidableTotal}（${suiteCoverage}%）。`
  );
  lines.push('');
  if (undecidableLines.size > 0) {
    lines.push(
      `另有 ${undecidableLines.size} 个顶层分支所有场景都判不了（条件依赖自定义函数的返回值），` +
        '不计入覆盖率分母，需人工或真机确认。'
    );
    lines.push('');
  }
  lines.push('## 一、场景结果');
  lines.push('');
  lines.push('| 场景 | 验证点 | 错误 | 告警 | 单场景覆盖 |');
  lines.push('|------|--------|------|------|------------|');
  for (const result of results) {
    lines.push(
      `| ${result.name} | ${result.expect} | ${result.errorCount} | ${result.warnCount} | ${result.coverage}% |`
    );
  }
  lines.push('');

  const scenariosWithFindings = results.filter((result) => result.findings.length > 0);
  lines.push('## 二、各场景问题明细');
  lines.push('');
  if (scenariosWithFindings.length === 0) {
    lines.push('所有场景均未发现问题。');
  } else {
    for (const result of scenariosWithFindings) {
      lines.push(`### ${result.name}`);
      lines.push('');
      lines.push('| 级别 | 类别 | 行号 | 说明 |');
      lines.push('|------|------|------|------|');
      for (const finding of result.findings) {
        lines.push(
          `| ${finding.severity} | ${finding.category} | ${finding.line} | ${finding.message} |`
        );
      }
      lines.push('');
    }
  }

  const neverCoveredBranches = allDataBranches.filter(
    (branch) => !coveredLines.has(branch.line) && !undecidableLines.has(branch.line)
  );
  lines.push('## 三、用例还缺的顶层分支');
  lines.push('');
  if (neverCoveredBranches.length === 0) {
    lines.push('无，所有可判定的顶层分区都至少被一个场景走到过。');
  } else {
    lines.push('这些分支在任何场景下都没走进去，补一组让条件为真的数据即可覆盖：');
    lines.push('');
    lines.push('| 行号 | 所属分区 | 条件 |');
    lines.push('|------|----------|------|');
    for (const branch of neverCoveredBranches) {
      lines.push(
        `| ${branch.line} | ${branch.section || '-'} | \`${branch.condition.replace(/\s+/g, ' ')}\` |`
      );
    }
  }
  lines.push('');

  const undecidableBranches = allDataBranches.filter((branch) =>
    undecidableLines.has(branch.line)
  );
  if (undecidableBranches.length > 0) {
    lines.push('## 四、静态分析判不了的顶层分支（需人工确认）');
    lines.push('');
    lines.push('| 行号 | 所属分区 | 条件 |');
    lines.push('|------|----------|------|');
    for (const branch of undecidableBranches) {
      lines.push(
        `| ${branch.line} | ${branch.section || '-'} | \`${branch.condition.replace(/\s+/g, ' ')}\` |`
      );
    }
    lines.push('');
  }

  const reportPath = resolve(
    dirname(templatePath),
    `${basename(templatePath).replace(/\.ftl$/, '')}.selftest-suite.md`
  );
  writeFileSync(reportPath, lines.join('\n'), 'utf8');

  console.log(`场景数：${results.length}`);
  for (const result of results) {
    const status = result.errorCount > 0 ? '不通过' : result.warnCount > 0 ? '有告警' : '通过';
    console.log(`  ${status.padEnd(4)} ${result.name}（覆盖 ${result.coverage}%）`);
  }
  console.log(`合并覆盖：${suiteCoverage}%`);
  console.log(`报告：${reportPath}`);

  process.exit(totalErrors > 0 ? 1 : 0);
}

main();
