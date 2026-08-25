#!/usr/bin/env node
/**
 * 内网 GitLab (gitlab.zbspos.com) 命令行助手。
 *
 * 用法：
 *   node gitlab/gitlab-api.mjs whoami
 *   node gitlab/gitlab-api.mjs project <项目路径>
 *   node gitlab/gitlab-api.mjs issues <项目路径> [状态]
 *   node gitlab/gitlab-api.mjs issue-create <项目路径> <标题> <正文文件>
 *   node gitlab/gitlab-api.mjs branch-create <项目路径> <新分支> <源分支>
 *   node gitlab/gitlab-api.mjs mr-create <项目路径> <源分支> <目标分支> <标题> <正文文件>
 *   node gitlab/gitlab-api.mjs mr-note <项目路径> <MR编号> <正文文件> [附件路径]
 *   node gitlab/gitlab-api.mjs mr-update <项目路径> <MR编号> <正文文件>
 *   node gitlab/gitlab-api.mjs upload <项目路径> <文件路径>
 *
 * 项目路径示例：posbee-microservice/print-util
 */

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, join } from 'node:path';

const GITLAB_HOST = 'https://gitlab.zbspos.com';
const API_BASE = `${GITLAB_HOST}/api/v4`;
const TOKEN_FILE = join(homedir(), '.zbspos-gitlab-token');

/** 读取访问令牌：优先环境变量，其次本地令牌文件（不入库） */
function loadAccessToken() {
  if (process.env.GITLAB_TOKEN) {
    return process.env.GITLAB_TOKEN.trim();
  }
  try {
    return readFileSync(TOKEN_FILE, 'utf8').trim();
  } catch {
    throw new Error(
      `未找到访问令牌。请设置环境变量 GITLAB_TOKEN，或把令牌写入 ${TOKEN_FILE}`
    );
  }
}

/** GitLab 要求项目路径做 URL 编码，斜杠转成 %2F */
function encodeProjectPath(projectPath) {
  return encodeURIComponent(projectPath);
}

async function callGitlabApi(method, endpoint, payload) {
  const accessToken = loadAccessToken();
  const requestOptions = {
    method,
    headers: { 'PRIVATE-TOKEN': accessToken },
  };
  if (payload) {
    requestOptions.headers['Content-Type'] = 'application/json';
    requestOptions.body = JSON.stringify(payload);
  }

  const response = await fetch(`${API_BASE}${endpoint}`, requestOptions);
  const rawBody = await response.text();

  if (!response.ok) {
    // 401 多为令牌失效或 scope 不足；404 在私有仓库上通常表示无权限而非不存在
    throw new Error(
      `GitLab 返回 ${response.status} ${response.statusText}\n${rawBody}`
    );
  }
  return rawBody ? JSON.parse(rawBody) : null;
}

/** 正文较长时统一从文件读取，避免命令行转义踩坑 */
function readBodyFile(filePath) {
  if (!filePath) return '';
  return readFileSync(filePath, 'utf8');
}

/**
 * 上传文件到项目附件区。
 * 附件存在 GitLab 的 uploads 空间，不进仓库、不产生提交，
 * 适合放自测报告这类「评审要看、但不该入库」的材料。
 */
async function uploadProjectFile(projectPath, filePath) {
  const accessToken = loadAccessToken();
  const formData = new FormData();
  formData.append('file', new Blob([readFileSync(filePath)]), basename(filePath));

  const response = await fetch(
    `${API_BASE}/projects/${encodeProjectPath(projectPath)}/uploads`,
    { method: 'POST', headers: { 'PRIVATE-TOKEN': accessToken }, body: formData }
  );
  const rawBody = await response.text();
  if (!response.ok) {
    throw new Error(`上传失败：GitLab 返回 ${response.status}\n${rawBody}`);
  }
  return JSON.parse(rawBody);
}

const commandHandlers = {
  async whoami() {
    const currentUser = await callGitlabApi('GET', '/user');
    return {
      用户名: currentUser.username,
      姓名: currentUser.name,
      账号ID: currentUser.id,
      状态: currentUser.state,
    };
  },

  /** 列出我有建项目权限的群组，用于决定新仓库放哪 */
  async groups() {
    const groupList = await callGitlabApi(
      'GET',
      '/groups?min_access_level=30&per_page=100&all_available=false'
    );
    return groupList.map((group) => ({
      群组ID: group.id,
      路径: group.full_path,
      名称: group.name,
      可见性: group.visibility,
    }));
  },

  async project(projectPath) {
    const project = await callGitlabApi(
      'GET',
      `/projects/${encodeProjectPath(projectPath)}`
    );
    return {
      项目ID: project.id,
      完整路径: project.path_with_namespace,
      默认分支: project.default_branch,
      可见性: project.visibility,
      我的权限: project.permissions?.project_access?.access_level ?? '继承自群组',
      仓库地址: project.http_url_to_repo,
    };
  },

  async issues(projectPath, state = 'opened') {
    const issueList = await callGitlabApi(
      'GET',
      `/projects/${encodeProjectPath(projectPath)}/issues?state=${state}&per_page=20`
    );
    return issueList.map((issue) => ({
      编号: issue.iid,
      标题: issue.title,
      状态: issue.state,
      链接: issue.web_url,
    }));
  },

  async 'issue-create'(projectPath, title, bodyFilePath) {
    const createdIssue = await callGitlabApi(
      'POST',
      `/projects/${encodeProjectPath(projectPath)}/issues`,
      { title, description: readBodyFile(bodyFilePath) }
    );
    return { 编号: createdIssue.iid, 链接: createdIssue.web_url };
  },

  async 'branch-create'(projectPath, branchName, sourceBranch) {
    const createdBranch = await callGitlabApi(
      'POST',
      `/projects/${encodeProjectPath(projectPath)}/repository/branches`,
      { branch: branchName, ref: sourceBranch }
    );
    return { 分支: createdBranch.name, 最新提交: createdBranch.commit?.short_id };
  },

  async 'mr-create'(projectPath, sourceBranch, targetBranch, title, bodyFilePath) {
    const currentUser = await callGitlabApi('GET', '/user');
    const createdMergeRequest = await callGitlabApi(
      'POST',
      `/projects/${encodeProjectPath(projectPath)}/merge_requests`,
      {
        source_branch: sourceBranch,
        target_branch: targetBranch,
        title,
        description: readBodyFile(bodyFilePath),
        // 指派给令牌所属账号，由人工负责评审与合并
        assignee_id: currentUser.id,
        remove_source_branch: true,
      }
    );
    return { 编号: createdMergeRequest.iid, 链接: createdMergeRequest.web_url };
  },

  async upload(projectPath, filePath) {
    const uploadResult = await uploadProjectFile(projectPath, filePath);
    return {
      文件名: uploadResult.alt,
      引用地址: uploadResult.url,
      markdown引用: uploadResult.markdown,
      说明: '该文件已存入 GitLab 附件区，未进入仓库，把 markdown 引用贴进 MR 描述或评论即可',
    };
  },

  /**
   * 给 MR 追加一条评论。
   * 正文文件可用 {{附件}} 占位，会被替换成附件的 markdown 引用。
   */
  async 'mr-note'(projectPath, mergeRequestIid, bodyFilePath, attachmentPath) {
    let noteBody = readBodyFile(bodyFilePath);

    if (attachmentPath) {
      const uploadResult = await uploadProjectFile(projectPath, attachmentPath);
      noteBody = noteBody.includes('{{附件}}')
        ? noteBody.replace('{{附件}}', uploadResult.markdown)
        : `${noteBody}\n\n完整报告：${uploadResult.markdown}`;
    }

    const createdNote = await callGitlabApi(
      'POST',
      `/projects/${encodeProjectPath(projectPath)}/merge_requests/${mergeRequestIid}/notes`,
      { body: noteBody }
    );
    return {
      评论ID: createdNote.id,
      链接: `${GITLAB_HOST}/${projectPath}/-/merge_requests/${mergeRequestIid}#note_${createdNote.id}`,
    };
  },

  /** 删除 MR 评论，用于清理重复内容 */
  async 'mr-note-delete'(projectPath, mergeRequestIid, noteId) {
    await callGitlabApi(
      'DELETE',
      `/projects/${encodeProjectPath(projectPath)}/merge_requests/${mergeRequestIid}/notes/${noteId}`
    );
    return { 已删除评论: noteId };
  },

  /** 覆盖 MR 描述，用于补充自测结论 */
  async 'mr-update'(projectPath, mergeRequestIid, bodyFilePath) {
    const updatedMergeRequest = await callGitlabApi(
      'PUT',
      `/projects/${encodeProjectPath(projectPath)}/merge_requests/${mergeRequestIid}`,
      { description: readBodyFile(bodyFilePath) }
    );
    return { 编号: updatedMergeRequest.iid, 链接: updatedMergeRequest.web_url };
  },
};

async function main() {
  const [commandName, ...commandArgs] = process.argv.slice(2);
  const handler = commandHandlers[commandName];

  if (!handler) {
    console.error(`未知命令：${commandName ?? '(空)'}`);
    console.error(`可用命令：${Object.keys(commandHandlers).join(', ')}`);
    process.exit(1);
  }

  try {
    const result = await handler(...commandArgs);
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

main();
