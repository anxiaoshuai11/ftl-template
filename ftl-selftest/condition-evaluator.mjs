/**
 * FreeMarker 表达式求值器（三态：true / false / unknown）。
 *
 * 覆盖小票模版里最常见的写法：
 *   路径??            存在性
 *   路径?has_content  非空
 *   路径?size gt N    集合长度
 *   路径 gte N        数值比较
 *   路径 == 值        相等比较
 *   路径?is_string    类型判断
 *   && || ! ()        逻辑组合
 *
 * 判不了的表达式（自定义函数调用、复杂内建组合）一律返回 unknown，
 * 由报告标注「需人工确认」，绝不猜一个 true/false 蒙混过去。
 *
 * elementScope 用于逐元素求值：把循环变量绑定到具体数据行后再判断分支，
 * 这样 `<#list mealInfo.contentList as mealItem>` 里的条件也能算出覆盖情况。
 */

export const TRUE = 'true';
export const FALSE = 'false';
export const UNKNOWN = 'unknown';

const PATH_PATTERN = /^[A-Za-z_][\w.[\]]*$/;

/** 沿路径逐段取值，段上可带数组下标 */
function walkSegments(startValue, segments) {
  let currentValue = startValue;
  for (const segment of segments) {
    const propertyName = segment.replace(/\[.*$/, '').trim();
    if (propertyName) {
      if (currentValue === null || typeof currentValue !== 'object') {
        return { status: 'missing' };
      }
      if (!(propertyName in currentValue)) {
        return { status: 'missing' };
      }
      currentValue = currentValue[propertyName];
    }
    for (const indexMatch of segment.matchAll(/\[(\d+)\]/g)) {
      const arrayIndex = Number(indexMatch[1]);
      if (!Array.isArray(currentValue) || arrayIndex >= currentValue.length) {
        return { status: 'missing' };
      }
      currentValue = currentValue[arrayIndex];
    }
  }
  return { status: 'resolved', value: currentValue };
}

/** 路径解析：resolved 命中值 / missing 数据里没有 / unknown 静态判不了 */
export function resolvePath(pathExpression, environment) {
  const cleanPath = pathExpression.trim();
  if (!PATH_PATTERN.test(cleanPath)) {
    return { status: UNKNOWN };
  }

  const segments = cleanPath.split('.');
  const rootName = segments[0].replace(/\[.*$/, '').trim();

  // 逐元素求值时，循环变量已绑定到具体数据行
  if (environment.elementScope && environment.elementScope.has(rootName)) {
    return walkSegments(environment.elementScope.get(rootName), segments.slice(1));
  }
  // 未绑定的循环变量与函数形参无法静态定位
  if (environment.loopVariables.has(rootName) || environment.localNames.has(rootName)) {
    return { status: UNKNOWN };
  }
  if (environment.assignValues.has(rootName)) {
    const assigned = environment.assignValues.get(rootName);
    if (assigned.state === UNKNOWN) return { status: UNKNOWN };
    return walkSegments(assigned.value, segments.slice(1));
  }
  return walkSegments(environment.dataRoot, segments);
}

/** FreeMarker 的 has_content：字符串非空、集合非空、对象有键 */
function hasContent(value) {
  if (value === null || value === undefined) return false;
  if (typeof value === 'string') return value.length > 0;
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === 'object') return Object.keys(value).length > 0;
  return true;
}

/** 取集合长度，取不到返回 null */
function measureSize(value) {
  if (Array.isArray(value) || typeof value === 'string') return value.length;
  if (value !== null && typeof value === 'object') return Object.keys(value).length;
  return null;
}

function toTriState(booleanValue) {
  return booleanValue ? TRUE : FALSE;
}

function compareNumbers(leftValue, operator, rightValue) {
  const comparisons = {
    gt: leftValue > rightValue,
    gte: leftValue >= rightValue,
    lt: leftValue < rightValue,
    lte: leftValue <= rightValue,
  };
  return comparisons[operator];
}

function parseLiteral(literalText) {
  const text = literalText.trim();
  if (/^".*"$/.test(text) || /^'.*'$/.test(text)) {
    return { ok: true, value: text.slice(1, -1) };
  }
  if (/^-?\d+(\.\d+)?$/.test(text)) {
    return { ok: true, value: Number(text) };
  }
  if (text === 'true') return { ok: true, value: true };
  if (text === 'false') return { ok: true, value: false };
  return { ok: false };
}

/** 求值单个原子表达式 */
function evaluateAtom(atomText, environment) {
  const text = atomText.trim();
  if (text === '') return UNKNOWN;

  const literal = parseLiteral(text);
  if (literal.ok && typeof literal.value === 'boolean') {
    return toTriState(literal.value);
  }

  // 存在性：路径??
  const existenceMatch = text.match(/^([\w.[\]]+)\?\?$/);
  if (existenceMatch) {
    const resolved = resolvePath(existenceMatch[1], environment);
    if (resolved.status === UNKNOWN) return UNKNOWN;
    if (resolved.status === 'missing') return FALSE;
    return toTriState(resolved.value !== null && resolved.value !== undefined);
  }

  // 非空：路径?has_content
  const hasContentMatch = text.match(/^([\w.[\]]+)\?has_content$/);
  if (hasContentMatch) {
    const resolved = resolvePath(hasContentMatch[1], environment);
    if (resolved.status === UNKNOWN) return UNKNOWN;
    if (resolved.status === 'missing') return FALSE;
    return toTriState(hasContent(resolved.value));
  }

  // 集合长度比较：路径?size gt|gte|lt|lte N
  const sizeMatch = text.match(/^([\w.[\]]+)\?size\s+(gt|gte|lt|lte)\s+(\d+)$/);
  if (sizeMatch) {
    const resolved = resolvePath(sizeMatch[1], environment);
    if (resolved.status === UNKNOWN) return UNKNOWN;
    if (resolved.status === 'missing') return FALSE;
    const sizeValue = measureSize(resolved.value);
    if (sizeValue === null) return UNKNOWN;
    return toTriState(compareNumbers(sizeValue, sizeMatch[2], Number(sizeMatch[3])));
  }

  // 数值比较：路径 gt|gte|lt|lte N
  const numericMatch = text.match(/^([\w.[\]]+)\s+(gt|gte|lt|lte)\s+(-?\d+(?:\.\d+)?)$/);
  if (numericMatch) {
    const resolved = resolvePath(numericMatch[1], environment);
    if (resolved.status !== 'resolved' || typeof resolved.value !== 'number') return UNKNOWN;
    return toTriState(compareNumbers(resolved.value, numericMatch[2], Number(numericMatch[3])));
  }

  // 类型判断：路径?is_string / ?is_number / ?is_hash / ?is_sequence
  const typeMatch = text.match(/^([\w.[\]]+)\?is_(string|number|hash|sequence|boolean)$/);
  if (typeMatch) {
    const resolved = resolvePath(typeMatch[1], environment);
    if (resolved.status === UNKNOWN) return UNKNOWN;
    if (resolved.status === 'missing') return FALSE;
    const actualValue = resolved.value;
    const typeCheckers = {
      string: typeof actualValue === 'string',
      number: typeof actualValue === 'number',
      hash: actualValue !== null && typeof actualValue === 'object' && !Array.isArray(actualValue),
      sequence: Array.isArray(actualValue),
      boolean: typeof actualValue === 'boolean',
    };
    return toTriState(typeCheckers[typeMatch[2]]);
  }

  // 相等比较：路径 == 字面量
  const equalityMatch = text.match(/^([\w.[\]]+)\s*(==|!=)\s*(.+)$/);
  if (equalityMatch) {
    const rightLiteral = parseLiteral(equalityMatch[3]);
    if (!rightLiteral.ok) return UNKNOWN;
    const resolved = resolvePath(equalityMatch[1], environment);
    if (resolved.status !== 'resolved') return UNKNOWN;
    const isEqual = resolved.value === rightLiteral.value;
    return toTriState(equalityMatch[2] === '==' ? isEqual : !isEqual);
  }

  // 裸路径当布尔量用
  if (PATH_PATTERN.test(text)) {
    const resolved = resolvePath(text, environment);
    if (resolved.status !== 'resolved') return UNKNOWN;
    if (typeof resolved.value === 'boolean') return toTriState(resolved.value);
    return UNKNOWN;
  }

  return UNKNOWN;
}

/** 把条件串切成 token 序列，括号与逻辑运算符单独成 token */
function tokenizeCondition(conditionText) {
  const tokens = [];
  let offset = 0;

  const previousIsOperand = () => {
    if (tokens.length === 0) return false;
    const lastToken = tokens[tokens.length - 1];
    return lastToken.type === 'ATOM' || lastToken.type === 'RPAREN';
  };

  while (offset < conditionText.length) {
    const currentChar = conditionText[offset];
    if (/\s/.test(currentChar)) {
      offset += 1;
      continue;
    }
    if (conditionText.startsWith('&&', offset)) {
      tokens.push({ type: 'AND' });
      offset += 2;
      continue;
    }
    if (conditionText.startsWith('||', offset)) {
      tokens.push({ type: 'OR' });
      offset += 2;
      continue;
    }
    if (currentChar === '(') {
      tokens.push({ type: 'LPAREN' });
      offset += 1;
      continue;
    }
    if (currentChar === ')') {
      tokens.push({ type: 'RPAREN' });
      offset += 1;
      continue;
    }
    // 前面没有操作数时的 `!` 是取反；否则是 FreeMarker 的默认值运算符，属于原子的一部分
    if (currentChar === '!' && !previousIsOperand() && conditionText[offset + 1] !== '=') {
      tokens.push({ type: 'NOT' });
      offset += 1;
      continue;
    }

    const atomStart = offset;
    let parenDepth = 0;
    let quoteChar = null;
    while (offset < conditionText.length) {
      const atomChar = conditionText[offset];
      if (quoteChar) {
        if (atomChar === quoteChar && conditionText[offset - 1] !== '\\') quoteChar = null;
        offset += 1;
        continue;
      }
      if (atomChar === '"' || atomChar === "'") {
        quoteChar = atomChar;
      } else if (atomChar === '(' || atomChar === '[') {
        parenDepth += 1;
      } else if (atomChar === ']') {
        parenDepth -= 1;
      } else if (atomChar === ')') {
        if (parenDepth === 0) break;
        parenDepth -= 1;
      } else if (
        parenDepth === 0 &&
        (conditionText.startsWith('&&', offset) || conditionText.startsWith('||', offset))
      ) {
        break;
      }
      offset += 1;
    }
    tokens.push({ type: 'ATOM', text: conditionText.slice(atomStart, offset) });
  }
  return tokens;
}

function combineAnd(leftState, rightState) {
  if (leftState === FALSE || rightState === FALSE) return FALSE;
  if (leftState === UNKNOWN || rightState === UNKNOWN) return UNKNOWN;
  return TRUE;
}

function combineOr(leftState, rightState) {
  if (leftState === TRUE || rightState === TRUE) return TRUE;
  if (leftState === UNKNOWN || rightState === UNKNOWN) return UNKNOWN;
  return FALSE;
}

/** 递归下降：或 → 与 → 一元 → 原子 */
function createParser(tokens, environment) {
  let cursor = 0;

  function parseOrExpression() {
    let state = parseAndExpression();
    while (cursor < tokens.length && tokens[cursor].type === 'OR') {
      cursor += 1;
      state = combineOr(state, parseAndExpression());
    }
    return state;
  }

  function parseAndExpression() {
    let state = parseUnaryExpression();
    while (cursor < tokens.length && tokens[cursor].type === 'AND') {
      cursor += 1;
      state = combineAnd(state, parseUnaryExpression());
    }
    return state;
  }

  function parseUnaryExpression() {
    const token = tokens[cursor];
    if (!token) return UNKNOWN;

    if (token.type === 'NOT') {
      cursor += 1;
      const innerState = parseUnaryExpression();
      if (innerState === UNKNOWN) return UNKNOWN;
      return innerState === TRUE ? FALSE : TRUE;
    }
    if (token.type === 'LPAREN') {
      cursor += 1;
      const innerState = parseOrExpression();
      if (tokens[cursor] && tokens[cursor].type === 'RPAREN') cursor += 1;
      return innerState;
    }
    if (token.type === 'ATOM') {
      cursor += 1;
      return evaluateAtom(token.text, environment);
    }
    cursor += 1;
    return UNKNOWN;
  }

  return parseOrExpression;
}

/** 对外入口：求一个条件表达式的三态结果 */
export function evaluateCondition(conditionText, environment) {
  if (!conditionText || !conditionText.trim()) return UNKNOWN;
  try {
    const tokens = tokenizeCondition(conditionText);
    return createParser(tokens, environment)();
  } catch {
    return UNKNOWN;
  }
}

/**
 * 求一个 #assign 右侧表达式的实际值。
 * 数值、字符串、布尔都要能算出来，否则 `contentSize == 2` 这类分支永远判不了。
 */
export function evaluateValue(expression, environment) {
  const text = expression.trim();
  if (!text) return { status: UNKNOWN };

  const literal = parseLiteral(text);
  if (literal.ok) return { status: 'resolved', value: literal.value };

  // 集合长度：路径?size
  const sizeMatch = text.match(/^([\w.[\]]+)\?size$/);
  if (sizeMatch) {
    const resolved = resolvePath(sizeMatch[1], environment);
    if (resolved.status !== 'resolved') return { status: UNKNOWN };
    const sizeValue = measureSize(resolved.value);
    return sizeValue === null ? { status: UNKNOWN } : { status: 'resolved', value: sizeValue };
  }

  // 默认值写法：路径!字面量 或 (路径)!字面量
  const defaultMatch = text.match(/^\(?\s*([\w.[\]]+)\s*\)?\s*!\s*(.+)$/);
  if (defaultMatch) {
    const resolved = resolvePath(defaultMatch[1], environment);
    if (resolved.status === 'resolved') return { status: 'resolved', value: resolved.value };
    if (resolved.status === 'missing') {
      const fallbackLiteral = parseLiteral(defaultMatch[2]);
      return fallbackLiteral.ok
        ? { status: 'resolved', value: fallbackLiteral.value }
        : { status: UNKNOWN };
    }
    return { status: UNKNOWN };
  }

  // 纯路径
  if (PATH_PATTERN.test(text)) {
    const resolved = resolvePath(text, environment);
    return resolved.status === 'resolved'
      ? { status: 'resolved', value: resolved.value }
      : { status: UNKNOWN };
  }

  // 兜底当布尔表达式算
  const conditionState = evaluateCondition(text, environment);
  if (conditionState === TRUE) return { status: 'resolved', value: true };
  if (conditionState === FALSE) return { status: 'resolved', value: false };
  return { status: UNKNOWN };
}
