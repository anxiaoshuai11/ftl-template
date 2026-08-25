#!/usr/bin/env node
/**
 * 改动前后回归对比。
 *
 * 用法：
 *   node ftl-selftest/run-regression.mjs <模版.ftl> <数据.json> [基线ref] [报告输出路径]
 *
 * 修改现有模版时，只知道「改完之后有几个问题」是不够的——得知道
 * 「哪些问题是这次改出来的」。本脚本从 git 取出基线版本（默认 HEAD），
 * 与工作区当前版本跑同一份数据，只报差异。
 *
 * 报告默认写在模版同级目录，而模版通常在目标仓库里，会污染工作区。
 * 提 MR 时报告是随 MR 上传的、不入库，所以请显式指定仓库外的输出路径。
 *
 * 退出码：0 = 没有新增问题，1 = 引入了新问题。
 */

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, relative, resolve } from 'node:path';
import { analyzeTemplate, SEVERITY_ERROR, SCOPE_DATA } from './run-selftest.mjs';
import { TRUE } from './condition-evaluator.mjs';

function runGit(repositoryPath, args) {
  return execFileSync('git', ['-C', repositoryPath, ...args], { encoding: 'utf8' });
}

/** 从 git 取出模版在基线版本上的内容 */
function readBaselineSource(templatePath, baselineRef) {
  const templateDirectory = dirname(resolve(templatePath));
  const repositoryRoot = runGit(templateDirectory, ['rev-parse', '--show-toplevel']).trim();
  const relativePath = relative(repositoryRoot, resolve(templatePath));
  return runGit(repositoryRoot, ['show', `${baselineRef}:${relativePath}`]);
}

/**
 * 问题指纹只取「类别 + 说明」，不含行号。
 * 改动会让下方代码整体位移，带行号比对会把大量老问题误报成新增。
 */
function fingerprintFinding(finding) {
  return `${finding.category}|${finding.severity}|${finding.message}`;
}

/** 按指纹分组，同一指纹可能出现多次（同一表达式写了好几处） */
function groupByFingerprint(findings) {
  const groups = new Map();
  for (const finding of findings) {
    const key = fingerprintFinding(finding);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(finding);
  }
  return groups;
}

/**
 * 对比两侧问题集合。
 * 同指纹按出现次数比较：现在比基线多出来的那几处算新增，反之算消除。
 */
function diffFindings(baselineFindings, currentFindings) {
  const baselineGroups = groupByFingerprint(baselineFindings);
  const currentGroups = groupByFingerprint(currentFindings);
  const introducedFindings = [];
  const resolvedFindings = [];

  for (const [key, currentItems] of currentGroups) {
    const baselineCount = baselineGroups.get(key)?.length || 0;
    introducedFindings.push(...currentItems.slice(baselineCount));
  }
  for (const [key, baselineItems] of baselineGroups) {
    const currentCount = currentGroups.get(key)?.length || 0;
    resolvedFindings.push(...baselineItems.slice(currentCount));
  }

  introducedFindings.sort((left, right) => left.line - right.line);
  resolvedFindings.sort((left, right) => left.line - right.line);
  return { introducedFindings, resolvedFindings };
}

function summarizeCoverage(analysis) {
  const dataBranches = analysis.branches.filter((branch) => branch.scope === SCOPE_DATA);
  const coveredBranches = dataBranches.filter((branch) => branch.state === TRUE);
  return {
    total: dataBranches.length,
    covered: coveredBranches.length,
    rate: dataBranches.length ? Math.round((coveredBranches.length / dataBranches.length) * 100) : 0,
  };
}

function main() {
  const [templatePath, dataPath, baselineRefArgument, reportPathArgument] = process.argv.slice(2);
  if (!templatePath || !dataPath) {
    console.error(
      '用法：node ftl-selftest/run-regression.mjs <模版.ftl> <数据.json> [基线ref] [报告输出路径]'
    );
    process.exit(1);
  }
  const baselineRef = baselineRefArgument || 'HEAD';

  let baselineSource;
  try {
    baselineSource = readBaselineSource(templatePath, baselineRef);
  } catch {
    console.error(
      `无法从 ${baselineRef} 取出 ${basename(templatePath)} 的基线版本。\n` +
        '如果这是新增模版（基线里还不存在），不需要回归对比，直接用 run-suite.mjs 即可。'
    );
    process.exit(1);
  }

  const currentSource = readFileSync(templatePath, 'utf8');
  const dataRoot = JSON.parse(readFileSync(dataPath, 'utf8'));

  if (baselineSource === currentSource) {
    console.log(`${basename(templatePath)} 与 ${baselineRef} 相比没有改动，无需回归对比。`);
    process.exit(0);
  }

  const baselineAnalysis = analyzeTemplate(baselineSource, dataRoot);
  const currentAnalysis = analyzeTemplate(currentSource, dataRoot);

  const { introducedFindings, resolvedFindings } = diffFindings(
    baselineAnalysis.findings,
    currentAnalysis.findings
  );

  const baselineCoverage = summarizeCoverage(baselineAnalysis);
  const currentCoverage = summarizeCoverage(currentAnalysis);

  const introducedErrorCount = introducedFindings.filter(
    (finding) => finding.severity === SEVERITY_ERROR
  ).length;

  const lines = [];
  lines.push(`# FTL 回归对比报告 · ${basename(templatePath)}`);
  lines.push('');
  lines.push(`> 基线：\`${baselineRef}\`　对比：工作区当前版本`);
  lines.push(`> 数据：\`${basename(dataPath)}\``);
  lines.push(`> 生成：${new Date().toLocaleString('zh-CN', { hour12: false })}`);
  lines.push('');
  lines.push('## 结论');
  lines.push('');
  lines.push(
    introducedFindings.length === 0
      ? `**无新增问题。** 本次改动没有引入新的空值风险、数组越界或指令闭合问题。`
      : `**引入了 ${introducedFindings.length} 个新问题**（其中错误级 ${introducedErrorCount} 个），见下表。`
  );
  lines.push('');
  lines.push(
    `顶层分区覆盖：${baselineCoverage.covered}/${baselineCoverage.total}（${baselineCoverage.rate}%）` +
      ` → ${currentCoverage.covered}/${currentCoverage.total}（${currentCoverage.rate}%）`
  );
  lines.push('');

  lines.push('## 一、本次改动引入的问题');
  lines.push('');
  if (introducedFindings.length === 0) {
    lines.push('无。');
  } else {
    lines.push('| 级别 | 类别 | 行号 | 说明 |');
    lines.push('|------|------|------|------|');
    for (const finding of introducedFindings) {
      lines.push(
        `| ${finding.severity} | ${finding.category} | ${finding.line} | ${finding.message} |`
      );
    }
  }
  lines.push('');

  lines.push('## 二、本次改动消除的问题');
  lines.push('');
  if (resolvedFindings.length === 0) {
    lines.push('无。');
  } else {
    lines.push('行号为基线版本中的位置。');
    lines.push('');
    lines.push('| 级别 | 类别 | 行号 | 说明 |');
    lines.push('|------|------|------|------|');
    for (const finding of resolvedFindings) {
      lines.push(
        `| ${finding.severity} | ${finding.category} | ${finding.line} | ${finding.message} |`
      );
    }
  }
  lines.push('');

  const baselineBranchLines = new Set(
    baselineAnalysis.branches.filter((branch) => branch.scope === SCOPE_DATA).map((b) => b.condition)
  );
  const newBranches = currentAnalysis.branches.filter(
    (branch) => branch.scope === SCOPE_DATA && !baselineBranchLines.has(branch.condition)
  );
  lines.push('## 三、新增的顶层分支');
  lines.push('');
  if (newBranches.length === 0) {
    lines.push('无，本次改动没有新增分区级判断。');
  } else {
    lines.push('这些是本次新加的分区判断，**必须补对应用例**，否则等于没测：');
    lines.push('');
    lines.push('| 行号 | 所属分区 | 条件 | 本次数据命中 |');
    lines.push('|------|----------|------|--------------|');
    for (const branch of newBranches) {
      const hitLabel = branch.state === TRUE ? '真' : branch.state === 'false' ? '假' : '判不了';
      lines.push(
        `| ${branch.line} | ${branch.section || '-'} | \`${branch.condition.replace(/\s+/g, ' ')}\` | ${hitLabel} |`
      );
    }
  }
  lines.push('');

  const reportPath = reportPathArgument
    ? resolve(reportPathArgument)
    : resolve(dirname(templatePath), `${basename(templatePath).replace(/\.ftl$/, '')}.regression.md`);
  writeFileSync(reportPath, lines.join('\n'), 'utf8');

  console.log(`基线：${baselineRef}`);
  console.log(`新增问题：${introducedFindings.length}（错误 ${introducedErrorCount}）`);
  console.log(`消除问题：${resolvedFindings.length}`);
  console.log(`新增顶层分支：${newBranches.length}`);
  console.log(`覆盖率：${baselineCoverage.rate}% → ${currentCoverage.rate}%`);
  console.log(`报告：${reportPath}`);

  process.exit(introducedFindings.length > 0 ? 1 : 0);
}

main();
