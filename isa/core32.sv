parameter OPSET_CORE32 = 4'b0;

typedef enum bit [4:0] {
	CORE32_NOP = 5'h00,
	CORE32_CPUID = 5'h01,
	CORE32_LDW = 5'h02,
	CORE32_LVI = 5'h03,
	CORE32_LLI = 5'h04,
	CORE32_STW = 5'h05,
	CORE32_MOV = 5'h06,
	CORE32_JA = 5'h07,
	CORE32_JAE = 5'h08,
	CORE32_JR = 5'h09,
	CORE32_JRE = 5'h0A,
	CORE32_JRNE = 5'h0B,
	CORE32_JRLT = 5'h0C,
	CORE32_JRGE = 5'h0E,
	CORE32_CALLA = 5'h10,
	CORE32_CALLR = 5'h11,
	CORE32_RET = 5'h12,
	CORE32_CMPU = 5'h13,
	CORE32_ADD = 5'h14,
	CORE32_ADDI = 5'h15,
	CORE32_MUL = 5'h16,
	CORE32_AND = 5'h17,
	CORE32_SHL = 5'h18,
	CORE32_SHLI = 5'h19,
	CORE32_INT = 5'h1A,
	CORE32_INTI = 5'h1B,
	CORE32_INTM = 5'h1C,
	CORE32_RETI = 5'h1D,
	CORE32_MCW = 5'h1E
} InstCore32;

typedef enum bit [1:0] {
	CORE32_CPUID_CPUID = 2'h0,
	CORE32_CPUID_CPUFT = 2'h1
} InstCore32_CPUID;

typedef enum bit [7:0] {
	CORE32_LDW_LDW = 8'h0,
	CORE32_LDW_LDHZ = 8'h1,
	CORE32_LDW_LDHS = 8'h2,
	CORE32_LDW_LDBZ = 8'h3,
	CORE32_LDW_LDBS = 8'h4
} InstCore32_LDW;

typedef enum bit [1:0] {
	CORE32_LLI_LLI = 2'h0,
	CORE32_LLI_LUI = 2'h1
} InstCore32_LLI;

typedef enum bit [7:0] {
	CORE32_STW_STW = 8'h0,
	CORE32_STW_STH = 8'h1,
	CORE32_STW_STB = 8'h2
} InstCore32_STW;

typedef enum bit [7:0] {
	CORE32_JAE_JAE = 8'h0,
	CORE32_JAE_JANE = 8'h1,
	CORE32_JAE_JALT = 8'h2,
	CORE32_JAE_JAGE = 8'h4
} InstCore32_JAE;

typedef enum bit [7:0] {
	CORE32_CMPU_CMPU = 8'h0,
	CORE32_CMPU_CMPS = 8'h1
} InstCore32_CMPU;

typedef enum bit [7:0] {
	CORE32_ADD_ADD = 8'h0,
	CORE32_ADD_SUB = 8'h1
} InstCore32_ADD;

typedef enum bit [7:0] {
	CORE32_AND_AND = 8'h0,
	CORE32_AND_OR = 8'h1,
	CORE32_AND_XOR = 8'h2
} InstCore32_AND;

typedef enum bit [1:0] {
	CORE32_SHL_SHL = 2'h0,
	CORE32_SHL_SHR = 2'h1,
	CORE32_SHL_SHSR = 2'h2
} InstCore32_SHL;

typedef enum bit [1:0] {
	CORE32_SHLI_SHLI = 2'h0,
	CORE32_SHLI_SHRI = 2'h1,
	CORE32_SHLI_SHSRI = 2'h2
} InstCore32_SHLI;

typedef enum bit [7:0] {
	CORE32_MCW_MCW = 8'h0,
	CORE32_MCW_MCH = 8'h1,
	CORE32_MCW_MCB = 8'h2
} InstCore32_MCW;