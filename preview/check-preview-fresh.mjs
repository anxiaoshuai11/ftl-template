#!/usr/bin/env node
/**
 * 预览 HTML 新鲜度校验。
 *
 * 预览是手工静态展开出来的，改了 FTL 却忘记重新生成，页面看着一切正常，
 * 只是停留在上一个版本——这类问题肉眼发现不了，只能靠指纹比对。
 *
 * 做法：生成预览后把源 FTL 的内容指纹盖进 HTML 头部注释，之后任何时候都能校验。
 *
 * 用法：
 *   node preview/check-preview-fresh.mjs <模版.ftl> [预览.html]           校验
 *   node preview/check-preview-fresh.mjs --stamp <模版.ftl> [预览.html]   生成预览后盖指纹
 */

import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, dirname, resolve } from 'node:path';

const FINGERPRINT_LABEL = 'source-sha256';

/** 指纹只取前 16 位，够区分版本又不至于让头部注释太难看 */
function computeFingerprint(fileContent) {
  return createHash('sha256').update(fileContent, 'utf8').digest('hex').slice(0, 16);
}

/** 预览文件默认与模版同名同目录，只是后缀换成 .preview.html */
function derivePreviewPath(templatePath) {
  const templateBaseName = basename(templatePath).replace(/\.ftl$/, '');
  return resolve(dirname(templatePath), `${templateBaseName}.preview.html`);
}

function readStampedFingerprint(previewContent) {
  const matched = previewContent.match(new RegExp(`${FINGERPRINT_LABEL}:\\s*([0-9a-f]+)`));
  return matched ? matched[1] : null;
}

/** 把指纹写进头部注释：已有则替换，没有则插在 generated-by 那行后面 */
function stampFingerprint(previewContent, fingerprint) {
  const stampLine = `  ${FINGERPRINT_LABEL}: ${fingerprint}`;

  if (readStampedFingerprint(previewContent)) {
    return previewContent.replace(
      new RegExp(`^\\s*${FINGERPRINT_LABEL}:\\s*[0-9a-f]+\\s*$`, 'm'),
      stampLine
    );
  }

  const generatedByLine = previewContent.match(/^.*generated-by:.*$/m);
  if (generatedByLine) {
    return previewContent.replace(generatedByLine[0], `${generatedByLine[0]}\n${stampLine}`);
  }

  // 连头部注释都没有的老预览，补一个完整的
  return `<!--\n${stampLine}\n-->\n${previewContent}`;
}

function main() {
  const commandArguments = process.argv.slice(2);
  const isStampMode = commandArguments[0] === '--stamp';
  const [templatePathArgument, previewPathArgument] = isStampMode
    ? commandArguments.slice(1)
    : commandArguments;

  if (!templatePathArgument) {
    console.error(
      [
        '用法：',
        '  node preview/check-preview-fresh.mjs <模版.ftl> [预览.html]           校验',
        '  node preview/check-preview-fresh.mjs --stamp <模版.ftl> [预览.html]   盖指纹',
      ].join('\n')
    );
    process.exit(1);
  }

  const templatePath = resolve(templatePathArgument);
  const previewPath = previewPathArgument
    ? resolve(previewPathArgument)
    : derivePreviewPath(templatePath);

  if (!existsSync(templatePath)) {
    console.error(`找不到模版：${templatePath}`);
    process.exit(1);
  }
  if (!existsSync(previewPath)) {
    console.error(
      `找不到预览文件：${previewPath}\n` +
        '改 FTL 必须同步产出预览，请先用 ftl-ticket-html-preview skill 生成。'
    );
    process.exit(1);
  }

  const currentFingerprint = computeFingerprint(readFileSync(templatePath, 'utf8'));
  const previewContent = readFileSync(previewPath, 'utf8');

  if (isStampMode) {
    writeFileSync(previewPath, stampFingerprint(previewContent, currentFingerprint), 'utf8');
    console.log(`已盖指纹 ${currentFingerprint} → ${basename(previewPath)}`);
    return;
  }

  const stampedFingerprint = readStampedFingerprint(previewContent);

  if (!stampedFingerprint) {
    console.error(
      [
        `预览文件没有指纹，无法判断是否为当前版本：${basename(previewPath)}`,
        '',
        '若已确认该预览就是当前 FTL 生成的，补盖指纹：',
        `  node preview/check-preview-fresh.mjs --stamp ${templatePathArgument}`,
        '否则请重新生成预览。',
      ].join('\n')
    );
    process.exit(1);
  }

  if (stampedFingerprint !== currentFingerprint) {
    console.error(
      [
        `预览已过期：${basename(previewPath)}`,
        `  预览记录的模版指纹：${stampedFingerprint}`,
        `  当前模版指纹：      ${currentFingerprint}`,
        '',
        'FTL 改过但预览没重新生成。请用 ftl-ticket-html-preview skill 重新生成后再提 MR，',
        '否则 MR 附件里的预览展示的是上一个版本的样式。',
      ].join('\n')
    );
    process.exit(1);
  }

  console.log(`预览是最新的（指纹 ${currentFingerprint}）：${basename(previewPath)}`);
}

main();
