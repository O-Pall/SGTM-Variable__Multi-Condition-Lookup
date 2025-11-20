___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Lookup - Multi-Condition",
  "description": "Multicriteria lookup table.\n- AND/OR logic with regular data types management (string, bool, numeric)\n- Returns undefined if no match\n\n75 tests provided.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "matchType",
    "displayName": "Type de logique",
    "macrosInSelect": false,
    "selectItems": [
      {
        "value": "AND",
        "displayValue": "AND (Most precise rule wins)"
      },
      {
        "value": "OR",
        "displayValue": "OR (First valid rule wins)"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "AND",
    "alwaysInSummary": true,
    "help": "Use .* to accept any value in the table below (joker)."
  },
  {
    "type": "LABEL",
    "name": "label_inputs",
    "displayName": "Input"
  },
  {
    "type": "GROUP",
    "name": "groupInput1",
    "displayName": "1 (mandatory)",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "TEXT",
        "name": "inputVar1",
        "displayName": "Choose a variable",
        "simpleValueType": true
      },
      {
        "type": "SELECT",
        "name": "inputType1",
        "displayName": "Data type",
        "selectItems": [
          {
            "value": "string",
            "displayValue": "String"
          },
          {
            "value": "boolean",
            "displayValue": "Boolean"
          },
          {
            "value": "number",
            "displayValue": "Numeric (floating included)"
          }
        ],
        "defaultValue": "string",
        "simpleValueType": true
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "groupInput2",
    "displayName": "2 (optional)",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "TEXT",
        "name": "inputVar2",
        "displayName": "Choose a variable",
        "simpleValueType": true
      },
      {
        "type": "SELECT",
        "name": "inputType2",
        "displayName": "Data type",
        "selectItems": [
          {
            "value": "string",
            "displayValue": "String"
          },
          {
            "value": "boolean",
            "displayValue": "Boolean"
          },
          {
            "value": "number",
            "displayValue": "Numeric (floating included)"
          }
        ],
        "defaultValue": "string",
        "simpleValueType": true
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "groupInput3",
    "displayName": "3 (optional)",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "TEXT",
        "name": "inputVar3",
        "displayName": "Choose a variable",
        "simpleValueType": true
      },
      {
        "type": "SELECT",
        "name": "inputType3",
        "displayName": "Data type",
        "selectItems": [
          {
            "value": "string",
            "displayValue": "String"
          },
          {
            "value": "boolean",
            "displayValue": "Boolean"
          },
          {
            "value": "number",
            "displayValue": "Numeric (floating included)"
          }
        ],
        "defaultValue": "string",
        "simpleValueType": true
      }
    ]
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "lookupList",
    "displayName": "Multi-condition Lookup table",
    "help": "Use \u0027.*\u0027 to accept any value (joker). Does not count in the precision score (AND logic).",
    "simpleTableColumns": [
      {
        "defaultValue": ".*",
        "displayName": "Input 1 (value to match)",
        "name": "match1",
        "type": "TEXT"
      },
      {
        "defaultValue": ".*",
        "displayName": "Input 2 (value to match)",
        "name": "match2",
        "type": "TEXT"
      },
      {
        "defaultValue": ".*",
        "displayName": "Input 3 (value to match)",
        "name": "match3",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Output",
        "name": "output",
        "type": "TEXT"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const makeString = require('makeString');
const makeNumber = require('makeNumber');
const getType = require('getType');

const matchType = data.matchType || 'AND';
const table = data.lookupList || [];

// --- HELPERS ---

const toBooleanish = (v) => {
  if (getType(v) === 'boolean') return v;
  if (v === undefined || v === null) return undefined;
  const s = makeString(v).trim().toLowerCase();
  const YES = ["1","true","oui","yes","on","vrai"];
  const NO  = ["0","false","non","no","off","faux"];
  if (YES.indexOf(s) !== -1) return true;
  if (NO.indexOf(s) !== -1) return false;
  return undefined;
};

const transformValue = (val, type) => {
  if (val === undefined || val === null) return undefined;
  if (type === 'boolean') return toBooleanish(val);
  if (type === 'number') return makeNumber(val);
  return makeString(val);
};

const val1 = transformValue(data.inputVar1, data.inputType1);
const val2 = transformValue(data.inputVar2, data.inputType2);
const val3 = transformValue(data.inputVar3, data.inputType3);

// --- LOGIQUE ---

let bestOutput = undefined;
let maxScore = -1;
const WILDCARD = '.*';

for (let i = 0; i < table.length; i++) {
  const row = table[i];
  
  // Les valeurs du tableau sont strings
  const cell1 = makeString(row.match1);
  const cell2 = makeString(row.match2);
  const cell3 = makeString(row.match3);

  const checkCondition = (cellValue, inputValue, type) => {
    // 1. Wildcard Check
    if (cellValue === WILDCARD) return 0; 

    // 2. Typed Check
    const typedCell = transformValue(cellValue, type);
    if (inputValue === typedCell) return 1; 
    
    return -1; 
  };

  const r1 = checkCondition(cell1, val1, data.inputType1);
  const r2 = checkCondition(cell2, val2, data.inputType2);
  const r3 = checkCondition(cell3, val3, data.inputType3);

  // --- MODE OR ---
  if (matchType === 'OR') {
    if (r1 >= 0 || r2 >= 0 || r3 >= 0) {
      return row.output;
    }
  } 
  
  // --- MODE AND (SCORING) ---
  else {
    if (r1 >= 0 && r2 >= 0 && r3 >= 0) {
      const currentScore = r1 + r2 + r3;
      
      if (currentScore > maxScore) {
        maxScore = currentScore;
        bestOutput = row.output;
      }
    }
  }
}

return bestOutput;


___TESTS___

scenarios:
- name: 01_AND_Basic_Match
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: '.*', inputType2: 'string', inputVar3: '.*', inputType3: 'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'OK'}] };
    assertThat(runCode(mockData)).isEqualTo('OK');
- name: 02_AND_Basic_NoMatch
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'B', inputType1: 'string', inputVar2: '.*', inputType2: 'string', inputVar3: '.*', inputType3: 'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'OK'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 03_AND_Exact_3_Matches
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'Perfect'}] };
    assertThat(runCode(mockData)).isEqualTo('Perfect');
- name: 04_AND_Wildcard_Middle
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'Z', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [{match1:'A', match2:'.*', match3:'C', output:'Wild'}] };
    assertThat(runCode(mockData)).isEqualTo('Wild');
- name: 05_AND_Wildcard_All
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'X', inputType1: 'string', inputVar2: 'Y', inputType2: 'string', inputVar3: 'Z', inputType3: 'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'CatchAll'}] };
    assertThat(runCode(mockData)).isEqualTo('CatchAll');
- name: 06_AND_Fail_One_Condition
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'Wrong', inputType3: 'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'Fail'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 07_Score_Priority_Specific_Vs_Generic
  code: |-
    // Generic (Score 1) vs Specific (Score 2). Specific wins even if second.
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [ {match1:'A', match2:'.*', match3:'.*', output:'Generic'}, {match1:'A', match2:'B', match3:'.*', output:'Specific'} ] };
    assertThat(runCode(mockData)).isEqualTo('Specific');
- name: 08_Score_Priority_Specific_Vs_Generic_Inversed
  code: |-
    // Generic (Score 1) vs Specific (Score 2). Specific wins even if first.
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [ {match1:'A', match2:'B', match3:'.*', output:'Specific'}, {match1:'A', match2:'.*', match3:'.*', output:'Generic'} ] };
    assertThat(runCode(mockData)).isEqualTo('Specific');
- name: 09_Score_Super_Specific_Wins
  code: |-
    // Score 3 vs Score 2 vs Score 1
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [ {match1:'A', match2:'.*', match3:'.*', output:'1'}, {match1:'A', match2:'B', match3:'.*', output:'2'}, {match1:'A', match2:'B', match3:'C', output:'3'} ] };
    assertThat(runCode(mockData)).isEqualTo('3');
- name: 10_Score_Tie_Breaker_Top_Down
  code: |-
    // Two rules with Score 1. First one in list wins.
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [ {match1:'A', match2:'.*', match3:'.*', output:'First'}, {match1:'.*', match2:'B', match3:'.*', output:'Second'} ] };
    assertThat(runCode(mockData)).isEqualTo('First');
- name: 11_OR_Basic_Match_Col1
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 'A', inputType1: 'string', inputVar2: 'Z', inputType2: 'string', inputVar3: 'Z', inputType3: 'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'OR_Match'}] };
    assertThat(runCode(mockData)).isEqualTo('OR_Match');
- name: 12_OR_Basic_Match_Col2
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 'Z', inputType1: 'string', inputVar2: 'B', inputType2: 'string', inputVar3: 'Z', inputType3: 'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'OR_Match'}] };
    assertThat(runCode(mockData)).isEqualTo('OR_Match');
- name: 13_OR_Basic_Match_Col3
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 'Z', inputType1: 'string', inputVar2: 'Z', inputType2: 'string', inputVar3: 'C', inputType3: 'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'OR_Match'}] };
    assertThat(runCode(mockData)).isEqualTo('OR_Match');
- name: 14_OR_Wildcard_Ignored
  code: |-
    // In OR mode, wildcard matches should count as a match.
    const mockData = { matchType: 'OR', inputVar1: 'X', inputType1: 'string', inputVar2: 'X', inputType2: 'string', inputVar3: 'X', inputType3: 'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'Wild'}] };
    assertThat(runCode(mockData)).isEqualTo('Wild');
- name: 15_OR_Priority_Top_Down
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 'A', inputType1: 'string', inputVar2: 'A', inputType2: 'string', inputVar3: 'A', inputType3: 'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Row1'}, {match1:'A', match2:'.*', match3:'.*', output:'Row2'}] };
    assertThat(runCode(mockData)).isEqualTo('Row1');
- name: 16_Type_String_Case_Sensitive
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'Purchase', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'purchase', match2:'.*', match3:'.*', output:'Low'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 17_Type_Number_Integer_StringInput
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '100', inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'100', match2:'.*', match3:'.*', output:'Num'}] };
    assertThat(runCode(mockData)).isEqualTo('Num');
- name: 18_Type_Number_Integer_NumberInput
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 100, inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'100', match2:'.*', match3:'.*', output:'Num'}] };
    assertThat(runCode(mockData)).isEqualTo('Num');
- name: 19_Type_Number_Float_Rounding
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '10.50', inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'10.5', match2:'.*', match3:'.*', output:'Float'}] };
    assertThat(runCode(mockData)).isEqualTo('Float');
- name: 20_Type_Boolean_True_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'true', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'Bool'}] };
    assertThat(runCode(mockData)).isEqualTo('Bool');
- name: 21_Type_Boolean_1_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '1', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'Bool'}] };
    assertThat(runCode(mockData)).isEqualTo('Bool');
- name: 22_Type_Boolean_Yes_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'yes', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'Bool'}] };
    assertThat(runCode(mockData)).isEqualTo('Bool');
- name: 23_Type_Boolean_False_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'false', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'false', match2:'.*', match3:'.*', output:'BoolFalse'}] };
    assertThat(runCode(mockData)).isEqualTo('BoolFalse');
- name: 24_Type_Boolean_0_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '0', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'false', match2:'.*', match3:'.*', output:'BoolFalse'}] };
    assertThat(runCode(mockData)).isEqualTo('BoolFalse');
- name: 25_Type_Boolean_Wildcard_Wins
  code: |-
    // Boolean input but table has wildcard.
    const mockData = { matchType: 'AND', inputVar1: true, inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'Wild'}] };
    assertThat(runCode(mockData)).isEqualTo('Wild');
- name: 26_Edge_Empty_String_Input
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'', match2:'.*', match3:'.*', output:'Empty'}] };
    assertThat(runCode(mockData)).isEqualTo('Empty');
- name: 27_Edge_Undefined_Input
  code: |-
    const mockData = { matchType: 'AND', inputVar1: undefined, inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'undefined', match2:'.*', match3:'.*', output:'Undef'}] };
    // Undefined input usually becomes string "undefined" or ignored. Based on makeString it might be "undefined".
    // In logic: transformValue(undefined) -> undefined. undefined != "undefined". No match.
    assertThat(runCode(mockData)).isUndefined();
- name: 28_Edge_Null_Input
  code: |-
    const mockData = { matchType: 'AND', inputVar1: null, inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'null', match2:'.*', match3:'.*', output:'Null'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 29_Mix_Num_Bool_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '100', inputType1: 'number', inputVar2: 'true', inputType2: 'boolean', inputVar3: 'test', inputType3: 'string', lookupList: [{match1:'100', match2:'true', match3:'test', output:'Mix'}] };
    assertThat(runCode(mockData)).isEqualTo('Mix');
- name: 30_Mix_Fail_On_Type
  code: |-
    // Input 100 (number), Table "100" (number) -> Match.
    // Input "false" (bool), Table "true" (bool) -> Fail.
    const mockData = { matchType: 'AND', inputVar1: '100', inputType1: 'number', inputVar2: 'false', inputType2: 'boolean', inputVar3: '.*', inputType3: 'string', lookupList: [{match1:'100', match2:'true', match3:'.*', output:'Mix'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 31_AND_Score_Complex_1
  code: |-
    // 3 inputs. Row 1 matches 2 inputs (Score 2). Row 2 matches 3 inputs (Score 3).
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'B', match3:'.*', output:'2Pts'}, {match1:'A', match2:'B', match3:'C', output:'3Pts'}] };
    assertThat(runCode(mockData)).isEqualTo('3Pts');
- name: 32_AND_Score_Complex_2
  code: |-
    // 3 inputs. Row 1 matches 1 input (Score 1). Row 2 matches 2 inputs (Score 2).
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'1Pts'}, {match1:'A', match2:'B', match3:'.*', output:'2Pts'}] };
    assertThat(runCode(mockData)).isEqualTo('2Pts');
- name: 33_AND_Score_Wildcard_Is_Zero
  code: |-
    // Row: .*, .*, .* -> Score 0. Matches, but lowest priority.
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'ZeroPts'}] };
    assertThat(runCode(mockData)).isEqualTo('ZeroPts');
- name: 34_String_Trim_Check
  code: |-
    // Table has " A ", input is "A". makeString usually doesn't trim automatically unless logic does.
    // The logic does NOT trim strings, only booleans. So this should fail or depend on makeString behavior.
    // Assuming strict match.
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:' A ', match2:'.*', match3:'.*', output:'Space'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 35_Bool_Case_Insensitive
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'TRUE', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'Bool'}] };
    assertThat(runCode(mockData)).isEqualTo('Bool');
- name: 36_Zero_Number_Vs_Zero_String
  code: |-
    // Input 0 (number). Table "0".
    const mockData = { matchType: 'AND', inputVar1: 0, inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'0', match2:'.*', match3:'.*', output:'Zero'}] };
    assertThat(runCode(mockData)).isEqualTo('Zero');
- name: 37_Zero_String_Vs_Zero_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '0', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'0', match2:'.*', match3:'.*', output:'Zero'}] };
    assertThat(runCode(mockData)).isEqualTo('Zero');
- name: 38_OR_No_Match_Returns_Undefined
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 'X', inputType1: 'string', inputVar2:'Y', inputType2:'string', inputVar3:'Z', inputType3:'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'None'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 39_AND_Input_Missing_Type_Config
  code: |-
    // If user forgot to select type (defaults to string usually in UI, but testing default param)
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1: undefined, inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'DefString'}] };
    assertThat(runCode(mockData)).isEqualTo('DefString');
- name: 40_Wildcard_In_Input
  code: |-
    // If the input variable itself is ".*". It should match a specific ".*" in table (if treated as string).
    const mockData = { matchType: 'AND', inputVar1: '.*', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'Meta'}] };
    assertThat(runCode(mockData)).isEqualTo('Meta');
- name: 41_Float_Precision
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 33.333, inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'33.333', match2:'.*', match3:'.*', output:'Precise'}] };
    assertThat(runCode(mockData)).isEqualTo('Precise');
- name: 42_Negative_Number
  code: |-
    const mockData = { matchType: 'AND', inputVar1: -5, inputType1: 'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'-5', match2:'.*', match3:'.*', output:'Neg'}] };
    assertThat(runCode(mockData)).isEqualTo('Neg');
- name: 43_Negative_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '-5', inputType1: 'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'-5', match2:'.*', match3:'.*', output:'Neg'}] };
    assertThat(runCode(mockData)).isEqualTo('Neg');
- name: 44_Bool_Off_Is_False
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'off', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'false', match2:'.*', match3:'.*', output:'False'}] };
    assertThat(runCode(mockData)).isEqualTo('False');
- name: 45_Bool_No_Is_False
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'no', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'false', match2:'.*', match3:'.*', output:'False'}] };
    assertThat(runCode(mockData)).isEqualTo('False');
- name: 46_Bool_On_Is_True
  code: |-
    const mockData = { matchType: 'AND', inputVar1: 'on', inputType1: 'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'True'}] };
    assertThat(runCode(mockData)).isEqualTo('True');
- name: 47_Manual_Score_Calculation_Check
  code: |-
    // 3 Inputs. Table: A, .*, C (Score 2). vs A, B, .* (Score 2).
    // Tie breaker: First one.
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'C', output:'First'}, {match1:'A', match2:'B', match3:'.*', output:'Second'}] };
    assertThat(runCode(mockData)).isEqualTo('First');
- name: 48_Score_With_Types
  code: |-
    // Input 1 (num), true (bool), A (string).
    // Row 1: 1, true, .* (Score 2).
    // Row 2: 1, true, A (Score 3).
    const mockData = { matchType: 'AND', inputVar1:'1', inputType1:'number', inputVar2:'true', inputType2:'boolean', inputVar3:'A', inputType3:'string', lookupList: [{match1:'1', match2:'true', match3:'.*', output:'2Pts'}, {match1:'1', match2:'true', match3:'A', output:'3Pts'}] };
    assertThat(runCode(mockData)).isEqualTo('3Pts');
- name: 49_Empty_Table
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', lookupList: [] };
    assertThat(runCode(mockData)).isUndefined();
- name: 50_Table_With_Empty_Row_Objects
  code: |-
    // Sometimes GTM sends partial objects?
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', lookupList: [{}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 51_Mixed_Wildcard_Format
  code: |-
    // Check if .* works in any position
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'.*', match2:'B', match3:'C', output:'MidWild'}] };
    assertThat(runCode(mockData)).isEqualTo('MidWild');
- name: 52_Mixed_Wildcard_Format_2
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'B', match3:'.*', output:'EndWild'}] };
    assertThat(runCode(mockData)).isEqualTo('EndWild');
- name: 53_Mixed_Wildcard_Format_3
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'C', output:'SplitWild'}] };
    assertThat(runCode(mockData)).isEqualTo('SplitWild');
- name: 54_Numeric_String_With_Spaces
  code: |-
    // Input " 100 " as number. makeNumber usually handles spaces.
    const mockData = { matchType: 'AND', inputVar1:' 100 ', inputType1:'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'100', match2:'.*', match3:'.*', output:'Spaced'}] };
    assertThat(runCode(mockData)).isEqualTo('Spaced');
- name: 55_Boolean_String_With_Spaces
  code: |-
    // Input " true " as boolean. toBooleanish trims.
    const mockData = { matchType: 'AND', inputVar1:' true ', inputType1:'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'SpacedBool'}] };
    assertThat(runCode(mockData)).isEqualTo('SpacedBool');
- name: 56_Very_Long_String_Match
  code: |-
    const longS = "This is a very long string to test if there are any limits or weird behaviors with length";
    const mockData = { matchType: 'AND', inputVar1: longS, inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1: longS, match2:'.*', match3:'.*', output:'Long'}] };
    assertThat(runCode(mockData)).isEqualTo('Long');
- name: 57_Special_Chars_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1: '@#$%', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'@#$%', match2:'.*', match3:'.*', output:'Special'}] };
    assertThat(runCode(mockData)).isEqualTo('Special');
- name: 58_OR_With_Types_Num
  code: |-
    const mockData = { matchType: 'OR', inputVar1: 100, inputType1:'number', inputVar2:'A', inputType2:'string', inputVar3:'A', inputType3:'string', lookupList: [{match1:'100', match2:'B', match3:'B', output:'OR_Num'}] };
    assertThat(runCode(mockData)).isEqualTo('OR_Num');
- name: 59_OR_With_Types_Bool
  code: |-
    const mockData = { matchType: 'OR', inputVar1: false, inputType1:'boolean', inputVar2:'A', inputType2:'string', inputVar3:'A', inputType3:'string', lookupList: [{match1:'false', match2:'B', match3:'B', output:'OR_Bool'}] };
    assertThat(runCode(mockData)).isEqualTo('OR_Bool');
- name: 60_Inputs_Undefined_But_Wildcards_Present
  code: |-
    // Input undefined. Type string. Table has .* -> Should match because .* accepts anything?
    // Logic: transformValue(undefined) -> undefined. checkCondition: wildcard returns 0 BEFORE typing.
    // So yes, undefined input matches .* row.
    const mockData = { matchType: 'AND', inputVar1: undefined, inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'CatchUndef'}] };
    assertThat(runCode(mockData)).isEqualTo('CatchUndef');
- name: 61_Numeric_Type_Mismatch_Handling
  code: |-
    // Input "abc" as number -> NaN. Table "100". NaN != 100.
    const mockData = { matchType: 'AND', inputVar1: 'abc', inputType1:'number', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'100', match2:'.*', match3:'.*', output:'NaN_Test'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 62_Boolean_Invalid_String
  code: |-
    // Input "random" as boolean -> undefined. Table "true". Fail.
    const mockData = { matchType: 'AND', inputVar1: 'random', inputType1:'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'InvalidBool'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 63_Undefined_Priority
  code: |-
    // If inputs are undefined, Specific match shouldn't happen, only wildcard.
    const mockData = { matchType: 'AND', inputVar1: undefined, inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Specific'}, {match1:'.*', match2:'.*', match3:'.*', output:'Wild'}] };
    assertThat(runCode(mockData)).isEqualTo('Wild');
- name: 64_Partial_Inputs_Configured
  code: |-
    // Only input 1 configured in GTM (others undefined). Table expects match on 1.
    const mockData = { matchType: 'AND', inputVar1: 'A', inputType1:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Partial'}] };
    assertThat(runCode(mockData)).isEqualTo('Partial');
- name: 65_Score_Max_Possible
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'A', match2:'B', match3:'C', output:'Max'}] };
    assertThat(runCode(mockData)).isEqualTo('Max');
- name: 66_Score_Zero_Possible
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'C', inputType3:'string', lookupList: [{match1:'.*', match2:'.*', match3:'.*', output:'Zero'}] };
    assertThat(runCode(mockData)).isEqualTo('Zero');
- name: 67_Output_Is_Number_String
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'12345'}] };
    assertThat(runCode(mockData)).isEqualTo('12345');
- name: 68_Table_Column_Missing
  code: |-
    // Robustness: Row missing match2 property? treated as undefined -> "" -> No match unless wildcard.
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'B', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match3:'.*', output:'MissingCol'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 69_Case_Sensitivity_Standard
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'a', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Case'}] };
    assertThat(runCode(mockData)).isUndefined();
- name: 70_Match_False_Boolean
  code: |-
    const mockData = { matchType: 'AND', inputVar1:false, inputType1:'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'false', match2:'.*', match3:'.*', output:'FalseBool'}] };
    assertThat(runCode(mockData)).isEqualTo('FalseBool');
- name: 71_Match_True_Boolean_From_1
  code: |-
    const mockData = { matchType: 'AND', inputVar1:1, inputType1:'boolean', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'true', match2:'.*', match3:'.*', output:'TrueInt'}] };
    assertThat(runCode(mockData)).isEqualTo('TrueInt');
- name: 72_Large_Table_Sim_Start
  code: |-
    // Simulate finding match at start of list
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Start'}, {match1:'B', match2:'.*', match3:'.*', output:'End'}] };
    assertThat(runCode(mockData)).isEqualTo('Start');
- name: 73_Large_Table_Sim_End
  code: |-
    // Simulate finding match at end of list
    const mockData = { matchType: 'AND', inputVar1:'B', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Start'}, {match1:'B', match2:'.*', match3:'.*', output:'End'}] };
    assertThat(runCode(mockData)).isEqualTo('End');
- name: 74_Dup_Rows_Score_Equality
  code: |-
    // Two exact same rows. First one wins.
    const mockData = { matchType: 'AND', inputVar1:'A', inputType1:'string', inputVar2:'.*', inputType2:'string', inputVar3:'.*', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'Row1'}, {match1:'A', match2:'.*', match3:'.*', output:'Row2'}] };
    assertThat(runCode(mockData)).isEqualTo('Row1');
- name: 75_Nothing_Matches_Everything_Undefined
  code: |-
    const mockData = { matchType: 'AND', inputVar1:'Z', inputType1:'string', inputVar2:'X', inputType2:'string', inputVar3:'Y', inputType3:'string', lookupList: [{match1:'A', match2:'.*', match3:'.*', output:'A'}] };
    assertThat(runCode(mockData)).isUndefined();


___NOTES___

Created on 20/11/2025 13:18:03


