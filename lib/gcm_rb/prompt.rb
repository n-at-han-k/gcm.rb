# frozen_string_literal: true

module GcmRb
  module Prompt
    TEMPLATE = <<~PROMPT
      Generate a Git commit message with its description and an appropriate emoji based on the provided Git diff.

      **Rules:**
      - Respond with only the commit message and description.
      - No explanations, no markdown formatting, no code block (```) wrappers.
      - Follow this format:

      `<type>: <emoji><message>`
      `<detailed description>`

      **Example output:**

      feat: Initial commit
      Initial commit description

      **Commit types and corresponding emojis:**

      | Type                        | Emoji             |
      |-----------------------------|-------------------|
      | Initial commit              | :tada:        |
      | Version tag                 | :bookmark:    |
      | New feature                 | :sparkles:     |
      | Bugfix                      | :bug:         |
      | Metadata                    | :card_index:  |
      | Documentation               | :books:       |
      | Documenting source code     | :bulb:        |
      | Performance                 | :racehorse:   |
      | Cosmetic                    | :lipstick:    |
      | Tests                       | :rotating_light: |
      | Adding a test               | :white_check_mark: |
      | Make a test pass            | :heavy_check_mark: |
      | General update              | :zap:          |
      | Improve format/structure    | :art:         |
      | Refactor code               | :hammer:      |
      | Removing code/files         | :fire:        |
      | Continuous Integration      | :green_heart: |
      | Security                    | :lock:        |
      | Upgrading dependencies      | :arrow_up:     |
      | Downgrading dependencies    | :arrow_down:   |
      | Lint                        | :shirt:       |
      | Translation                 | :alien:       |
      | Text                        | :pencil:       |
      | Critical hotfix             | :ambulance:   |
      | Deploying stuff             | :rocket:      |
      | Fixing on MacOS             | :apple:       |
      | Fixing on Linux             | :penguin:     |
      | Fixing on Windows           | :checkered_flag: |
      | Work in progress            | :construction: |
      | Adding CI build system      | :construction_worker: |
      | Analytics or tracking code  | :chart_with_upwards_trend: |
      | Removing a dependency       | :heavy_minus_sign: |
      | Adding a dependency         | :heavy_plus_sign: |
      | Docker                      | :whale:        |
      | Configuration files         | :wrench:       |
      | Package.json in JS          | :package:      |
      | Merging branches            | :twisted_rightwards_arrows: |
      | Bad code / needs improvement| :hankey:       |
      | Reverting changes           | :rewind:       |
      | Breaking changes            | :boom:         |
      | Code review changes         | :ok_hand:      |
      | Accessibility               | :wheelchair:   |
      | Move/rename repository      | :truck:        |

      Now respond with the commit message for the following Git diff:

    PROMPT

    def self.build(diff)
      "#{TEMPLATE}#{diff}"
    end
  end
end
