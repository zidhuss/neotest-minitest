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
    })
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

### Default configuration

> **Note**: You only need to the call the `setup` function if you wish to change any of the defaults

<details>
  <summary>Show default configuration</summary>

```lua
adapters = {
  require("neotest-minitest")({
    test_cmd = function()
      return vim.tbl_flatten({
        "bundle",
        "exec",
        "ruby",
        "-Itest",
      })
    end,
  }),
}
```

</details>

### The test command

The command used to run tests can be changed via the `test_cmd` option e.g.

```lua
require("neotest-minitest")({
  test_cmd = function()
    return vim.tbl_flatten({
      "bundle",
      "exec",
      "rails",
      "test",
    })
  end
})
```

### Running tests in a Docker container

The following configuration overrides `test_cmd` to run a Docker container (using `docker-compose`) and overrides `transform_spec_path` to pass the spec file as a relative path instead of an absolute path to Minitest. The `results_path` needs to be set to a location which is available to both the container and the host.

```lua
require("neotest").setup({
  adapters = {
    require("neotest-minitest")({
      test_cmd = function()
        return vim.tbl_flatten({
          "docker",
          "compose",
          "exec",
          "-i",
          "-w", "/app",
          "-e", "RAILS_ENV=test",
          "app",
          "bundle",
          "exec",
          "test"
        })
      end,

      transform_spec_path = function(path)
        local prefix = require('neotest-minitest').root(path)
        return string.sub(path, string.len(prefix) + 2, -1)
      end,

      results_path = "tmp/minitest.output"
    })
  }
})
```

Alternatively, you can accomplish this using a shell script as your Minitest command. See [this comment](https://github.com/nvim-neotest/neotest/issues/89#issuecomment-1338141432) for an example.

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
