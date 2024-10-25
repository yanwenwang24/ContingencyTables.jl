"""
    ExpectedFrequency(ct::ContingencyResults)

Calculate expected frequencies under the assumption of independence for a contingency table.

# Arguments
- `ct::ContingencyResults`: Contingency table results

# Returns
- `DataFrame`: DataFrame containing the expected frequencies with the same structure as the input

# Notes
- For a two-way table, expected frequency for cell (i,j) is:
  E[i,j] = (row_total[i] × column_total[j]) / grand_total
- If the table is one-way, returns the same frequencies as input
- Maintains original row/column names and structure

# Examples
```julia
# Create contingency table
x1 = ["A", "A", "B", "B", "B"]
x2 = [1, 2, 1, 2, 2]
ct = ContingencyTable(x1, x2)

# Calculate expected frequencies
expected = ExpectedFrequency(ct)
```
"""

function ExpectedFrequency(ct::ContingencyResults)
    df = ct.counts
    
    # For one-way tables, return the same frequencies
    if size(df, 2) == 2  # Value and Count columns only
        return copy(df)
    end
    
    # Extract the count matrix (exclude Row column)
    observed = Matrix{Float64}(df[:, 2:end])
    
    # Calculate row and column totals
    row_totals = sum(observed, dims=2)
    col_totals = sum(observed, dims=1)
    grand_total = sum(observed)
    
    # Calculate expected frequencies
    expected = (row_totals * col_totals) ./ grand_total
    
    # Create DataFrame with same structure as input
    result = DataFrame(Row = df.Row)
    for (i, col) in enumerate(names(df)[2:end])
        result[!, col] = expected[:, i]
    end
    
    return result
end