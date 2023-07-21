# neotest-minitest

This plugin provides a [minitest](https://docs.seattlerb.org/minitest/) adapter for the [Neotest](https://github.com/nvim-neotest/neotest) framework.

## :package: Installation

Install with the package manager of your choice:

**Lazy**

```lua
{
  "nvim-neotest/neotest",
  lazy = true,
  dependencies = {
    ...,
    "zidhuss/neotest-minitest",
  },
  config = function()
    require("neotest").setup({
      ...,
      adapters = {
        require("neotest-minitest")
      },
    }
  end
}
```

<details>
    <summary><strong>Packer</strong></summary>

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    ...,
    'zidhuss/neotest-minitest',
  },
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-minitest'),
      }
    })
  end
})
```
</details>

## :wrench: Configuration

> TODO

## :rocket: Usage

_NOTE_: All usages of `require('neotest').run.run` can be mapped to a command in your config (this is not included and should be done by yourself).

#### Test single function

To test a single test, hover over the test and run `require('neotest').run.run()`

#### Test file

To test a file run `require('neotest').run.run(vim.fn.expand('%'))`

## :gift: Contributing

This project is maintained by the Neovim Ruby community. Please raise a PR if you are interested in adding new functionality or fixing any bugs. When submitting a bug, please include an example test.

To trigger the tests for the adapter, run:

```sh
make test
```

## :clap: Thanks

Special thanks to [Oli Morris](https://github.com/olimorris) and others for their work on [neotest-rspec](https://github.com/olimorris/neotest-rspec) that inspired this adapter.
