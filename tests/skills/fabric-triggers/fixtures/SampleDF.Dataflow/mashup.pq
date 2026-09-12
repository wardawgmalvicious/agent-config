[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared SampleRows = let
  Source = #table(
    type table [Item = text, Id = Int64.Type],
    {{"Dataflow", 1}, {"Pipeline", 2}}
  ),
  #"Changed column type" = Table.TransformColumnTypes(Source, {{"Item", type text}, {"Id", Int64.Type}}),
  #"Filtered rows" = Table.SelectRows(#"Changed column type", each [Item] = "Dataflow")
in
  #"Filtered rows";
