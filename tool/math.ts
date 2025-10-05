import { tool } from "@opencode-ai/plugin"

export const add = tool({
  description: "Add two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a + args.b
  },
})

export const multiply = tool({
  description: "Multiply two numbers",
  args: {
    a: tool.schema.number().describe("First number"),
    b: tool.schema.number().describe("Second number"),
  },
  async execute(args) {
    return args.a * args.b
  },
})

export const subtract = tool({
    description: "Subtract two numbers",
    args: {
        a: tool.schema.number().describe("First number"),
        b: tool.schema.number().describe("Second number"),
    },
    async execute(args) {
        return args.a - args.b
    },
})

export const divide = tool({
    description: "Divide two numbers",
    args: {
        a: tool.schema.number().describe("First number"),
        b: tool.schema.number().describe("Second number"),
    },
    async execute(args) {
        if (args.b === 0) {
            throw new Error("Division by zero is not allowed.")
        }
        return args.a / args.b
    },
})

export const squareRoot = tool({
    description: "Calculate the square root of a number",
    args: {
        a: tool.schema.number().describe("The number to calculate the square root of"),
    },
    async execute(args) {
        if (args.a < 0) {
            throw new Error("Cannot calculate the square root of a negative number.")
        }
        return Math.sqrt(args.a)
    },
})

export const power = tool({
    description: "Raise a number to the power of another number",
    args: {
        base: tool.schema.number().describe("The base number"),
        exponent: tool.schema.number().describe("The exponent number"),
    },
    async execute(args) {
        return Math.pow(args.base, args.exponent)
    },
})

export const factorial = tool({
    description: "Calculate the factorial of a number",
    args: {
        n: tool.schema.number().int().min(0).describe("The number to calculate the factorial of"),
    },
    async execute(args) {
        if (args.n === 0 || args.n === 1) {
            return 1
        }
        let result = 1
        for (let i = 2; i <= args.n; i++) {
            result *= i
        }
        return result
    },
})

export const modulus = tool({
    description: "Calculate the modulus of two numbers",
    args: {
        a: tool.schema.number().describe("The dividend"),
        b: tool.schema.number().describe("The divisor"),
    },
    async execute(args) {
        if (args.b === 0) {
            throw new Error("Division by zero is not allowed.")
        }
        return args.a % args.b
    },
})
