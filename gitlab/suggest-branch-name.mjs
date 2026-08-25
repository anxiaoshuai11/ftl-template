#!/usr/bin/env node
/**
 * 分支命名推断。
 *
 * 用法：
 *   node gitlab/suggest-branch-name.mjs <仓库路径> [需求名slug] [feature|hotfix]
 *
 * 不同仓库的命名习惯不一样（有的 需求名_作者_日期，有的 需求名_日期_作者，
 * 还有的只有日期没作者），照搬别的仓库的规范会格格不入。
 * 本脚本读目标仓库的历史分支统计出真实格式，并优先参考最近的分支——
 * 命名习惯会演进，老分支的写法未必还作数。
 */

import { execFileSync } from 'node:child_process';

const DATE_PATTERN = /^\d{8}$/;
const TYPE_PREFIXES = new Set(['feature', 'hotfix', 'fix', 'feat', 'bugfix']);
const RECENT_BRANCH_COUNT = 12;

const LAYOUT_DATE_FIRST = '需求名_日期_作者';
const LAYOUT_AUTHOR_FIRST = '需求名_作者_日期';
const LAYOUT_DATE_ONLY = '需求名_日期（无作者）';
const LAYOUT_NO_DATE = '需求名（无日期）';

function runGit(repositoryPath, args) {
  return execFileSync('git', ['-C', repositoryPath, ...args], { encoding: 'utf8' });
}

/** 按提交时间倒序列出分支，越靠前越新 */
function listBranchNames(repositoryPath) {
  const rawOutput = runGit(repositoryPath, [
    'branch',
    '-a',
    '--sort=-committerdate',
    '--format=%(refname:short)',
  ]);
  const seen = new Set();
  const branchNames = [];
  for (const rawLine of rawOutput.split('\n')) {
    const line = rawLine.trim();
    if (!line || line.includes('->')) continue;
    const normalized = line.replace(/^origin\//, '');
    if (seen.has(normalized)) continue;
    seen.add(normalized);
    branchNames.push(normalized);
  }
  return branchNames;
}

/** 收集仓库所有提交人的姓名与邮箱前缀，作为识别作者段的依据 */
function collectCommitterTokens(repositoryPath) {
  const rawOutput = runGit(repositoryPath, ['log', '--all', '--format=%an|%ae']);
  const committerTokens = new Set();
  for (const line of rawOutput.split('\n')) {
    const [authorName, authorEmail] = line.split('|');
    if (authorName) committerTokens.add(authorName.toLowerCase().replace(/\s+/g, ''));
    if (authorEmail) committerTokens.add(authorEmail.split('@')[0].toLowerCase());
  }
  return [...committerTokens].filter((token) => token.length >= 3);
}

/** token 的字符是否按顺序出现在 fullName 里（wjh ⊂ wangjianhui、sdy ⊂ sundeyao） */
function isSubsequence(token, fullName) {
  let nameCursor = 0;
  for (const character of token) {
    nameCursor = fullName.indexOf(character, nameCursor);
    if (nameCursor === -1) return false;
    nameCursor += 1;
  }
  return true;
}

/**
 * 判断某一段是不是作者代号。
 * 仓库里作者段常是缩写（wjh / jany / sdy / xiaowh），跟提交人姓名对不上字面，
 * 但一定是姓名或邮箱前缀的有序子序列，用这个特征来认。
 */
function isAuthorLike(token, committerTokens) {
  if (!token || token.length < 2 || DATE_PATTERN.test(token)) return false;
  const normalized = token.toLowerCase();
  return committerTokens.some(
    (committerToken) =>
      committerToken.startsWith(normalized) || isSubsequence(normalized, committerToken)
  );
}

function classifyBranch(branchName, committerTokens) {
  const slashIndex = branchName.indexOf('/');
  if (slashIndex === -1) return null;

  const typePrefix = branchName.slice(0, slashIndex);
  if (!TYPE_PREFIXES.has(typePrefix)) return null;

  const segments = branchName.slice(slashIndex + 1).split('_');
  const dateIndex = segments.findIndex((segment) => DATE_PATTERN.test(segment));

  if (dateIndex === -1) {
    const lastSegment = segments[segments.length - 1];
    return {
      branchName,
      layout: LAYOUT_NO_DATE,
      authorToken: isAuthorLike(lastSegment, committerTokens) ? lastSegment : null,
    };
  }

  const segmentsAfterDate = segments.slice(dateIndex + 1);
  if (segmentsAfterDate.length > 0) {
    return { branchName, layout: LAYOUT_DATE_FIRST, authorToken: segmentsAfterDate[0] };
  }

  // 日期在末尾：要看它前面那段是不是作者，否则就是「只有日期、没有作者」
  const tokenBeforeDate = dateIndex >= 1 ? segments[dateIndex - 1] : null;
  if (isAuthorLike(tokenBeforeDate, committerTokens)) {
    return { branchName, layout: LAYOUT_AUTHOR_FIRST, authorToken: tokenBeforeDate };
  }
  return { branchName, layout: LAYOUT_DATE_ONLY, authorToken: null };
}

function tallyLayouts(classifications) {
  const layoutCounts = new Map();
  for (const item of classifications) {
    layoutCounts.set(item.layout, (layoutCounts.get(item.layout) || 0) + 1);
  }
  return [...layoutCounts.entries()].sort((left, right) => right[1] - left[1]);
}

function buildBranchName(layout, typePrefix, requirementSlug, authorName, dateText) {
  const layoutBuilders = {
    [LAYOUT_DATE_FIRST]: `${typePrefix}/${requirementSlug}_${dateText}_${authorName}`,
    [LAYOUT_AUTHOR_FIRST]: `${typePrefix}/${requirementSlug}_${authorName}_${dateText}`,
    [LAYOUT_DATE_ONLY]: `${typePrefix}/${requirementSlug}_${dateText}`,
    [LAYOUT_NO_DATE]: `${typePrefix}/${requirementSlug}_${authorName}`,
  };
  return layoutBuilders[layout];
}

function main() {
  const [repositoryPath, requirementSlug, typeArgument] = process.argv.slice(2);
  if (!repositoryPath) {
    console.error(
      '用法：node gitlab/suggest-branch-name.mjs <仓库路径> [需求名slug] [feature|hotfix]'
    );
    process.exit(1);
  }

  const committerTokens = collectCommitterTokens(repositoryPath);
  const branchNames = listBranchNames(repositoryPath);
  const allClassifications = branchNames
    .map((branchName) => classifyBranch(branchName, committerTokens))
    .filter(Boolean);
  const recentClassifications = allClassifications.slice(0, RECENT_BRANCH_COUNT);

  const overallTally = tallyLayouts(allClassifications);
  const recentTally = tallyLayouts(recentClassifications);
  const dominantLayout = recentTally.length > 0 ? recentTally[0][0] : null;

  const authorSamples = [
    ...new Set(recentClassifications.map((item) => item.authorToken).filter(Boolean)),
  ].slice(0, 5);

  const gitUserName = runGit(repositoryPath, ['config', 'user.name']).trim();
  const today = new Date();
  const dateText =
    `${today.getFullYear()}` +
    `${String(today.getMonth() + 1).padStart(2, '0')}` +
    `${String(today.getDate()).padStart(2, '0')}`;

  console.log(`仓库：${repositoryPath}`);
  console.log(`可识别分支：${allClassifications.length} 条`);
  console.log('');
  console.log(`最近 ${recentClassifications.length} 条分支的格式（以此为准，命名习惯会演进）：`);
  for (const [layout, count] of recentTally) {
    console.log(`  ${count} 条  ${layout}${layout === dominantLayout ? '  ← 采用' : ''}`);
  }
  console.log('');
  console.log('全部历史分支的格式分布（仅供参考）：');
  for (const [layout, count] of overallTally) {
    console.log(`  ${count} 条  ${layout}`);
  }
  console.log('');
  console.log(
    authorSamples.length > 0
      ? `作者段实例：${authorSamples.join(' / ')}`
      : '作者段：最近的分支里没有作者段'
  );
  console.log(`git config user.name：${gitUserName}`);
  console.log('');

  if (!dominantLayout) {
    console.log('历史分支不足以判断格式，请人工确认命名规范。');
    return;
  }

  const typePrefix = typeArgument || 'feature';
  console.log(
    `本仓库格式：${buildBranchName(dominantLayout, typePrefix, '{需求名}', '{作者}', dateText)}`
  );

  if (requirementSlug) {
    const needsAuthor =
      dominantLayout === LAYOUT_DATE_FIRST ||
      dominantLayout === LAYOUT_AUTHOR_FIRST ||
      dominantLayout === LAYOUT_NO_DATE;
    const longAuthorName = gitUserName.replace(/\s+/g, '');
    // 本仓库已用过 user.name 全名写法时就直接用，否则要求人工确认代号
    const userNameAlreadyUsed = authorSamples.some(
      (sample) => sample.toLowerCase() === longAuthorName.toLowerCase()
    );
    const authorName = !needsAuthor
      ? ''
      : userNameAlreadyUsed
        ? longAuthorName
        : '{填你在本仓库的代号}';

    console.log('');
    console.log('建议分支名：');
    console.log(
      `  ${buildBranchName(dominantLayout, typePrefix, requirementSlug, authorName, dateText)}`
    );
    if (needsAuthor && authorSamples.length > 0 && !userNameAlreadyUsed) {
      console.log('');
      console.log(
        `本仓库作者段用的是代号（${authorSamples.join(' / ')}），` +
          `不是 user.name 的「${longAuthorName}」，请确认你在本仓库用哪个。`
      );
    }
  }
}

main();
