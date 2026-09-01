/**
 * 自测报告落盘位置的统一裁决。
 *
 * 模版通常躺在业务仓库里（如 print-util 的 templates 目录），报告默认写在模版旁边
 * 就等于写进了别人的工作区。报告是过程材料，提 MR 时走 GitLab 附件区，不该入库。
 *
 * 这里不靠人记纪律，直接在写文件之前拦下来。
 */

import { execFileSync } from 'node:child_process';
import { basename, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** 取某个目录所属的 git 仓库根目录；不在仓库里则返回 null */
function findGitRepoRoot(startDirectory) {
  try {
    return execFileSync('git', ['-C', startDirectory, 'rev-parse', '--show-toplevel'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return null;
  }
}

/**
 * 工具自身所在的仓库根目录，报告写在这里是允许的（本来就是工具的工作目录）。
 * 中文路径必须用 fileURLToPath 还原，直接取 URL.pathname 会拿到百分号编码，
 * 导致 git 找不到目录、误判成「不在仓库里」，进而把正常场景也拦掉。
 */
function findToolRepoRoot() {
  return findGitRepoRoot(dirname(fileURLToPath(import.meta.url)));
}

/**
 * 决定报告写到哪里，顺带拦截「写进目标仓库」。
 *
 * @param templatePath        模版路径，用来推导默认报告名
 * @param reportPathArgument  命令行显式指定的报告路径，可为空
 * @param reportSuffix        默认报告名后缀，如 `.selftest-suite.md`
 * @returns 解析后的绝对路径
 */
export function resolveReportPath(templatePath, reportPathArgument, reportSuffix) {
  const templateBaseName = basename(templatePath).replace(/\.ftl$/, '');
  const reportPath = reportPathArgument
    ? resolve(reportPathArgument)
    : resolve(dirname(templatePath), `${templateBaseName}${reportSuffix}`);

  const reportRepoRoot = findGitRepoRoot(dirname(reportPath));
  const toolRepoRoot = findToolRepoRoot();

  // 报告落在工具自己的工作目录里没问题；落进其它仓库一律拦下
  if (reportRepoRoot && reportRepoRoot !== toolRepoRoot) {
    const suggestedPath = `/tmp/${templateBaseName}${reportSuffix}`;
    throw new Error(
      [
        `拒绝把报告写进目标仓库：${reportRepoRoot}`,
        `  本次报告路径：${reportPath}`,
        '',
        '自测报告是过程材料，提交进模版仓库会污染变更文件列表。',
        `请把报告输出路径显式指到仓库外，例如：`,
        `  ${suggestedPath}`,
        '',
        '提 MR 时用 gitlab/gitlab-api.mjs upload 把报告挂到附件区。',
      ].join('\n')
    );
  }

  return reportPath;
}

/** CLI 入口统一包一层：把纪律类报错打成人话，而不是甩一坨调用栈 */
export function runCli(mainFunction) {
  try {
    mainFunction();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
