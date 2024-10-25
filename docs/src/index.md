# ContingencyTables.jl

ContingencyTables.jl is a Julia package for creating and analyzing contingency tables, with support for both one and two-dimensional analyses, weighted counts, and categorical data.

## Overview

This package provides tools for:

- Creating contingency tables from raw data
- Calculating proportions and conditional probabilities
- Handling missing values and weighted counts
- Working with categorical data while preserving order
- Analyzing both one and two-dimensional relationships

## Installation

To install the package, use Julia's package manager:

```julia
using Pkg
Pkg.add("ContingencyTables")
```

## Quick Start Guide

Here are some basic examples to get you started:

```julia
using ContingencyTables

# Single variable analysis
x = [1, 2, 2, 3, 3, 3]
ct = ContingencyTable(x)
println("Frequency table:")
println(ct.counts)

# Calculate proportions
pt = ProportionTable(ct)
println("\nProportions:")
println(pt.proportions)
```

### Two-Dimensional Analysis

```julia
# Create sample data
x1 = ["A", "B", "A", "C"]
x2 = [1, 2, 1, 3]

# Create cross-tabulation
ct2 = ContingencyTable(x1, x2)
println("Cross-tabulation:")
println(ct2.counts)

# Calculate row proportions (conditional probabilities)
pt2 = ProportionTable(ct2, dims=:row)
println("\nRow proportions:")
println(pt2.proportions)
```

### Working with Categorical Data

```julia
using CategoricalArrays

# Create ordered categorical data
x = categorical(["Low", "Med", "Low", "High"], ordered=true)
ct = ContingencyTable(x)
println("Ordered categorical frequencies:")
println(ct.counts)
```

## Features

### Core Functionality

- One and two-dimensional contingency tables
- Proportion calculations (total, row, and column)
- Support for weighted counts
- Missing value handling
- Categorical data support with level preservation

### Data Input Support

- Vector inputs
- DataFrame column analysis
- Categorical and non-categorical data
- Multiple input formats for flexibility

### Analysis Options

- Total proportions
- Row proportions (conditional probabilities)
- Column proportions (conditional probabilities)
- Weighted and unweighted counts

## Usage Examples

Check out the [Examples](@ref examples) section for detailed usage examples and the [API Reference](@ref) for complete function documentation.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests on our [GitHub repository](https://github.com/yanwenwang24/ContingencyTables.jl).

## License

This package is licensed under the MIT License - see the [LICENSE](https://github.com/yanwenwang24/ContingencyTables.jl/blob/main/LICENSE) file for details.