# ContingencyTables.jl

[![Build Status](https://github.com/yanwenwang24/ContingencyTables.jl/workflows/CI/badge.svg)](https://github.com/yanwenwang24/ContingencyTables.jl/actions)
[![Coverage](https://codecov.io/gh/yanwenwang24/ContingencyTables.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/yanwenwang24/ContingencyTables.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

📊 A Julia package for creating contingency/proportion tables.

## Features

- Create one- and two-dimensional contingency tables with a clean, intuitive API
- Calculate proportions and conditional probabilities with ease
- Support for weighted observations
- Ssupport for categorical data (ordered and unordered)
- Integration with DataFrames
- Clean, readable output formatting

## Installation

```julia
using Pkg
Pkg.add("ContingencyTables")
```

## Quick Start and Examples

```julia
using ContingencyTables
using DataFrames
using CategoricalArrays
```

### One-dimensional Analysis

```julia
# Basic usage with a vector
x = [1, 2, 2, 3, missing]
ct = ContingencyTable(x)
println(ct.counts)  # Shows frequency of each value

# With categorical data
severity = categorical(["Low", "Med", "High", "Low"], ordered=true)
ct = ContingencyTable(severity)
pt = ProportionTable(ct)  # Get proportions
```

### Two-dimensional Analysis

```julia
# Create a two-way table
ct = ContingencyTable(df, :severity, :region)

# Calculate different types of proportions:
joint_prob = ProportionTable(ct)                # Joint probabilities
row_prob = ProportionTable(ct, dims=:row)       # P(region|severity)
col_prob = ProportionTable(ct, dims=:col)       # P(severity|region)
```

### Expected Frequencies

Calculate expected frequencies under the assumption of independence:

```julia
x1 = ["A", "A", "B", "B"]
x2 = [1, 2, 1, 2]
ct = ContingencyTable(x1, x2)
expected = ExpectedFrequency(ct)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
