# API Reference

## Types

```@docs
ContingencyResults
ProportionResults
```

## Functions

### Core Functions

```@docs
ContingencyTable
ProportionTable
```

### Helper Functions

```@docs
create_contingency_results
create_proportion_results
```

## One-Dimensional Analysis

The package provides functions for analyzing single variables:

```@example
using ContingencyTables

x = [1, 2, 2, 3, 3, 3]
ct = ContingencyTable(x)
```

## Two-Dimensional Analysis

For cross-tabulation and conditional probability analysis:

```@example
using ContingencyTables

# Create sample data
x1 = ["A", "B", "A", "C"]
x2 = [1, 2, 1, 3]

# Create contingency table
ct = ContingencyTable(x1, x2)

# Calculate different types of proportions
prop_total = ProportionTable(ct)               # Total proportions
prop_row = ProportionTable(ct, dims=:row)      # Row proportions
prop_col = ProportionTable(ct, dims=:col)      # Column proportions
```

## Working with Missing Values

The package handles missing values through the `skipmissing` parameter:

```@example
using ContingencyTables

# Data with missing values
x = [1, 2, missing, 2, 3]

# Include missing values in the analysis
ct1 = ContingencyTable(x, skipmissing=false)

# Exclude missing values
ct2 = ContingencyTable(x, skipmissing=true)
```

## Weighted Counts

You can provide weights for observations:

```@example
using ContingencyTables

x = [1, 2, 2, 3]
weights = [1.0, 2.0, 0.5, 1.5]
ct = ContingencyTable(x, weights=weights)
```

## Categorical Data Support

The package preserves ordering and levels of categorical data:

```@example
using ContingencyTables
using CategoricalArrays

# Create ordered categorical data
x = categorical(["Low", "Med", "High"], ordered=true)
ct = ContingencyTable(x)
```