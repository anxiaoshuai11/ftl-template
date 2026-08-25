/**
 * FreeMarker 模版扫描器。
 *
 * 不做完整语法解析，只提取自测需要的四类信息：
 *   1. 指令（#if / #list / #assign / #function 等），含起止行号
 *   2. 插值表达式 ${...}
 *   3. #assign 变量名与右侧表达式
 *   4. #list 的「数据源 → 循环变量」映射
 *
 * 已知限制：条件里若用裸 `>` 做比较（如 `<#if a > 0>`）会被误判为指令结束，
 * 小票模版统一用 `gt` / `gte`，正常不会触发。
 */

/** 把注释替换成等长空白，保留换行以便行号不偏移 */
export function blankComments(source) {
  return source.replace(/<#--[\s\S]*?-->/g, (comment) =>
    comment.replace(/[^\n]/g, ' ')
  );
}

/** 预先算好每个字符偏移对应的行号，避免重复扫描 */
function buildLineIndex(source) {
  const lineStartOffsets = [0];
  for (let offset = 0; offset < source.length; offset += 1) {
    if (source[offset] === '\n') {
      lineStartOffsets.push(offset + 1);
    }
  }
  return lineStartOffsets;
}

function offsetToLine(lineStartOffsets, offset) {
  let low = 0;
  let high = lineStartOffsets.length - 1;
  while (low < high) {
    const middle = Math.ceil((low + high) / 2);
    if (lineStartOffsets[middle] <= offset) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low + 1;
}

/**
 * 从参数起点向后找指令结束的 `>`。
 * 括号内和引号内的 `>` 不算结束，用于兼容 `?then((n > 4), 1)` 这类写法。
 */
function findDirectiveEnd(source, startOffset) {
  let parenDepth = 0;
  let quoteChar = null;
  for (let offset = startOffset; offset < source.length; offset += 1) {
    const currentChar = source[offset];
    if (quoteChar) {
      if (currentChar === quoteChar && source[offset - 1] !== '\\') {
        quoteChar = null;
      }
      continue;
    }
    if (currentChar === '"' || currentChar === "'") {
      quoteChar = currentChar;
    } else if (currentChar === '(' || currentChar === '[') {
      parenDepth += 1;
    } else if (currentChar === ')' || currentChar === ']') {
      parenDepth -= 1;
    } else if (currentChar === '>' && parenDepth <= 0) {
      return offset;
    }
  }
  return -1;
}

/** 提取所有指令，按出现顺序返回 */
export function scanDirectives(source) {
  const lineStartOffsets = buildLineIndex(source);
  const directives = [];
  const directiveStartPattern = /<(\/?)#([a-zA-Z_]+)/g;
  let startMatch = directiveStartPattern.exec(source);

  while (startMatch !== null) {
    const isClosing = startMatch[1] === '/';
    const directiveName = startMatch[2];
    const paramStartOffset = startMatch.index + startMatch[0].length;
    const endOffset = findDirectiveEnd(source, paramStartOffset);

    if (endOffset !== -1) {
      const rawParams = source.slice(paramStartOffset, endOffset).trim();
      directives.push({
        name: directiveName,
        isClosing,
        // 自闭合写法 <#xxx ... /> 结尾会多一个斜杠，去掉后再用
        params: rawParams.endsWith('/') ? rawParams.slice(0, -1).trim() : rawParams,
        line: offsetToLine(lineStartOffsets, startMatch.index),
        offset: startMatch.index,
      });
      directiveStartPattern.lastIndex = endOffset + 1;
    }
    startMatch = directiveStartPattern.exec(source);
  }
  return directives;
}

/** 找到与 `${` 配对的右花括号，兼容嵌套与字符串 */
function findInterpolationEnd(source, startOffset) {
  let braceDepth = 1;
  let quoteChar = null;
  for (let offset = startOffset; offset < source.length; offset += 1) {
    const currentChar = source[offset];
    if (quoteChar) {
      if (currentChar === quoteChar && source[offset - 1] !== '\\') {
        quoteChar = null;
      }
      continue;
    }
    if (currentChar === '"' || currentChar === "'") {
      quoteChar = currentChar;
    } else if (currentChar === '{') {
      braceDepth += 1;
    } else if (currentChar === '}') {
      braceDepth -= 1;
      if (braceDepth === 0) {
        return offset;
      }
    }
  }
  return -1;
}

/** 提取所有 ${...} 插值 */
export function scanInterpolations(source) {
  const lineStartOffsets = buildLineIndex(source);
  const interpolations = [];
  let searchOffset = 0;

  while (searchOffset < source.length) {
    const dollarOffset = source.indexOf('${', searchOffset);
    if (dollarOffset === -1) break;
    const endOffset = findInterpolationEnd(source, dollarOffset + 2);
    if (endOffset === -1) break;

    interpolations.push({
      expression: source.slice(dollarOffset + 2, endOffset).trim(),
      line: offsetToLine(lineStartOffsets, dollarOffset),
      offset: dollarOffset,
    });
    searchOffset = endOffset + 1;
  }
  return interpolations;
}

/** 解析 `<#assign 名称 = 表达式>`，忽略无等号的块级 assign */
export function parseAssign(params) {
  const equalSignOffset = params.indexOf('=');
  if (equalSignOffset === -1) return null;

  const variableName = params.slice(0, equalSignOffset).trim();
  if (!/^[A-Za-z_]\w*$/.test(variableName)) return null;

  return {
    variableName,
    expression: params.slice(equalSignOffset + 1).trim(),
  };
}

/** 解析 `<#list 数据源 as 循环变量>`，返回数据源路径与变量名 */
export function parseList(params) {
  const listMatch = params.match(/^(.+?)\s+as\s+([A-Za-z_]\w*)\s*(?:,\s*([A-Za-z_]\w*))?$/s);
  if (!listMatch) return null;

  return {
    sourceExpression: listMatch[1].trim(),
    itemVariable: listMatch[3] ? listMatch[3] : listMatch[2],
    keyVariable: listMatch[3] ? listMatch[2] : null,
  };
}

/** 解析 `<#function 名称 参数1 参数2>`，用于识别自定义函数与其形参 */
export function parseFunction(params) {
  const tokens = params.trim().split(/\s+/);
  if (tokens.length === 0) return null;

  return {
    functionName: tokens[0],
    parameterNames: tokens.slice(1),
  };
}
