#!/usr/bin/env node
/**
 * 探测目标仓库有哪些「可安全执行的验证手段」。
 *
 * 用法：
 *   node workflow/detect-verification.mjs <仓库路径>
 *
 * 为什么需要它：通用工作流不该给每种技术栈重造一个检查器，
 * 而该发现并执行仓库里已经有的验证手段。但命令名不可信——
 * 本组前端仓库的 `make test` 实际是「把分支合进 test 分支并 push」，
 * 是部署动作而非测试。按名字猜会把代码推上共享环境。
 * 所以这里一律读命令内容再判定，判不了的宁可标成「需人工确认」。
 */

import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const SAFE = '可安全执行';
const DANGEROUS = '有副作用·勿自动执行';
const UNKNOWN = '需人工确认';

/** 命令内容里出现这些，说明会改远端或改分支状态，绝不能自动跑 */
const SIDE_EFFECT_PATTERNS = [
  /\bgit\s+push\b/,
  /\bgit\s+checkout\b/,
  /\bgit\s+merge\b/,
  /\bgit\s+reset\s+--hard\b/,
  /\bgit\s+stash\s+drop\b/,
  /\bgit\s+clean\b/,
  /\bgit\s+branch\s+-D\b/,
  /\bnpm\s+publish\b/,
  /\bdeploy\b/,
  /\bscp\b|\brsync\b/,
];

/** 命令内容里出现这些，才认定是真正的验证动作 */
const VERIFY_PATTERNS = [
  { pattern: /\b(vitest|jest|mocha|karma|cypress|playwright)\b/, kind: '单元/集成测试' },
  { pattern: /\beslint\b|vue-cli-service\s+lint|\bstylelint\b|\bprettier\s+--check/, kind: '代码检查' },
  { pattern: /\btsc\b|vue-tsc|--noEmit/, kind: '类型检查' },
  { pattern: /vue-cli-service\s+build|\bvite\s+build\b|\bwebpack\b|\btsc\s+-p/, kind: '构建' },
  { pattern: /\bmvn\b.*\b(test|verify)\b/, kind: '单元测试' },
  { pattern: /\bgradle\b.*\btest\b/, kind: '单元测试' },
];

function classifyCommand(commandText) {
  if (SIDE_EFFECT_PATTERNS.some((pattern) => pattern.test(commandText))) {
    return { level: DANGEROUS, kind: '部署/改分支' };
  }
  const matched = VERIFY_PATTERNS.find((item) => item.pattern.test(commandText));
  if (matched) return { level: SAFE, kind: matched.kind };
  return { level: UNKNOWN, kind: '用途不明' };
}

/** 解析 package.json 的 scripts */
function detectNpmScripts(repositoryPath) {
  const packagePath = join(repositoryPath, 'package.json');
  if (!existsSync(packagePath)) return [];

  const scripts = JSON.parse(readFileSync(packagePath, 'utf8')).scripts || {};
  return Object.entries(scripts).map(([scriptName, scriptBody]) => {
    const classification = classifyCommand(scriptBody);
    return {
      source: 'package.json',
      command: `npm run ${scriptName}`,
      detail: scriptBody,
      ...classification,
    };
  });
}

/**
 * 解析 Makefile 的目标与其命令体。
 * 目标行形如 `name:`，其下以 Tab 开头的行是命令体，判定必须看命令体。
 */
function detectMakefileTargets(repositoryPath) {
  const makefilePath = ['makefile', 'Makefile', 'GNUmakefile']
    .map((name) => join(repositoryPath, name))
    .find((candidate) => existsSync(candidate));
  if (!makefilePath) return [];

  const lines = readFileSync(makefilePath, 'utf8').split('\n');
  const targets = [];
  let currentTarget = null;

  for (const line of lines) {
    const targetMatch = /^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:(?!=)/.exec(line);
    if (targetMatch) {
      if (currentTarget) targets.push(currentTarget);
      currentTarget = { name: targetMatch[1], body: '' };
      continue;
    }
    if (currentTarget && /^\t/.test(line)) {
      currentTarget.body += `${line}\n`;
    }
  }
  if (currentTarget) targets.push(currentTarget);

  return targets.map((target) => {
    const classification = classifyCommand(target.body);
    return {
      source: 'Makefile',
      command: `make ${target.name}`,
      detail: target.body.trim().split('\n')[0]?.trim() || '(空)',
      ...classification,
    };
  });
}

/** Maven 项目：有测试目录才认为 mvn test 有意义 */
function detectMaven(repositoryPath) {
  if (!existsSync(join(repositoryPath, 'pom.xml'))) return [];

  const hasTestSources = existsSync(join(repositoryPath, 'src/test'));
  return [
    {
      source: 'pom.xml',
      command: 'mvn -q test',
      detail: hasTestSources ? '存在 src/test 测试源码' : '未发现 src/test，可能没有测试用例',
      level: hasTestSources ? SAFE : UNKNOWN,
      kind: hasTestSources ? '单元测试' : '无测试源码',
    },
    {
      source: 'pom.xml',
      command: 'mvn -q compile',
      detail: '编译能过，至少保证语法与依赖正确',
      level: SAFE,
      kind: '构建',
    },
  ];
}

/** CI 配置是团队已认可的验证标准，值得单独提示 */
function detectCiConfig(repositoryPath) {
  const ciPath = join(repositoryPath, '.gitlab-ci.yml');
  if (!existsSync(ciPath)) return [];
  return [
    {
      source: '.gitlab-ci.yml',
      command: '(见 CI 配置)',
      detail: 'CI 里跑什么，本地就该跑什么——这是团队已认可的验证标准',
      level: UNKNOWN,
      kind: 'CI 流水线',
    },
  ];
}

function main() {
  const repositoryPathArgument = process.argv[2];
  if (!repositoryPathArgument) {
    console.error('用法：node workflow/detect-verification.mjs <仓库路径>');
    process.exit(1);
  }
  const repositoryPath = resolve(repositoryPathArgument);

  const candidates = [
    ...detectNpmScripts(repositoryPath),
    ...detectMakefileTargets(repositoryPath),
    ...detectMaven(repositoryPath),
    ...detectCiConfig(repositoryPath),
  ];

  const safeItems = candidates.filter((item) => item.level === SAFE);
  const dangerousItems = candidates.filter((item) => item.level === DANGEROUS);
  const unknownItems = candidates.filter((item) => item.level === UNKNOWN);

  console.log(`仓库：${repositoryPath}`);
  console.log('');

  console.log(`【${SAFE}】${safeItems.length} 项`);
  if (safeItems.length === 0) {
    console.log('  无。本仓库没有可自动执行的验证手段。');
  }
  for (const item of safeItems) {
    console.log(`  ${item.command.padEnd(28)} ${item.kind}`);
  }
  console.log('');

  if (dangerousItems.length > 0) {
    console.log(`【${DANGEROUS}】${dangerousItems.length} 项 —— 名字像验证，实际会改远端，不要自动跑`);
    for (const item of dangerousItems) {
      console.log(`  ${item.command.padEnd(28)} ${item.kind}`);
    }
    console.log('');
  }

  if (unknownItems.length > 0) {
    console.log(`【${UNKNOWN}】${unknownItems.length} 项`);
    for (const item of unknownItems) {
      console.log(`  ${item.command.padEnd(28)} ${item.detail}`);
    }
    console.log('');
  }

  // 仓库自带的提 MR 脚本会推远端且产出形态不受控，本流程统一走 GitLab API
  const localMergeRequestScript = dangerousItems.find((item) => /\bmr\b|merge/i.test(item.command));
  if (localMergeRequestScript) {
    console.log('【注意：本仓库有本地提 MR 脚本】');
    console.log(`  ${localMergeRequestScript.command} —— 不要执行。它会推远端、改分支状态。`);
    console.log('  提 MR 统一用 gitlab/gitlab-api.mjs 调 API 创建。');
    console.log('');
  }

  const safeKinds = [...new Set(safeItems.map((item) => item.kind))];
  const hasRealTest = safeKinds.some((kind) => kind.includes('测试'));

  console.log('结论：');
  if (safeItems.length === 0) {
    console.log('  本仓库无可自动执行的验证手段，改动只能靠人工验证与评审。');
    console.log('  MR 里必须如实写明这一点，不要暗示「已测试」。');
  } else if (!hasRealTest) {
    console.log(`  可跑：${safeKinds.join(' / ')}；但本仓库没有单元测试。`);
    console.log('  代码检查与构建通过不等于功能正确，MR 里要写明功能验证是人工做的。');
  } else {
    console.log(`  可跑：${safeKinds.join(' / ')}。改动前后都应跑一遍，并在 MR 中附结果。`);
  }

  process.exit(0);
}

main();
