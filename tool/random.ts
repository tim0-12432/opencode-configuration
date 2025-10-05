import { tool } from "@opencode-ai/plugin"

export const int = tool({
  description: "Generate a random integer",
  args: {
    min: tool.schema.number().describe("Minimum value"),
    max: tool.schema.number().describe("Maximum value"),
  },
  async execute(args) {
    return Math.floor(Math.random() * (args.max - args.min + 1)) + args.min
  },
})

export const dice = tool({
  description: "Roll a dice",
  args: {},
  async execute(args) {
    return Math.floor(Math.random() * 6) + 1
  },
})

export const coin = tool({
  description: "Flip a coin",
  args: {},
  async execute(args) {
    return Math.random() < 0.5 ? "heads" : "tails"
  },
})

export const pick = tool({
    description: "Pick a random item from a list",
    args: {
        items: tool.schema.array(tool.schema.string()).describe("List of items to choose from"),
    },
    async execute(args) {
        if (args.items.length === 0) {
            throw new Error("The list of items cannot be empty.")
        }
        const index = Math.floor(Math.random() * args.items.length)
        return args.items[index]
    },
})
