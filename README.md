# populate-tree-view
populating tree structure from Category

```delphi
  qryCategory.Close;
  try
    qryCategory.Open('SELECT id, CategoryName, ParentId FROM Categories');
    qryCategory.First;

    BuildTree(nil, 0);

  finally
    qryCategory.Close;
  end;
```

```delphi
procedure TfrmProductList.BuildTree(ATreeNode: TTreeNode; AParentId: integer);
var
  TreeParent, TreeChild: TTreeNode;
begin
  var tmpQuery := TFDQuery.Create(nil);
  tmpQuery.Connection := DM.LocalConnection;
  try
    // root node
    if ATreeNode = nil then
    begin
      TreeView1.Items.Clear();
      while not(qryCategory.eof) do
      begin
        if qryCategory.FieldByName('ParentID').AsInteger = 0 then
        begin
          var name := qryCategory.FieldByName('CategoryName').AsString;
          TreeParent := TreeView1.Items.Add(nil, name);
          // child nodes
          tmpQuery.Open(format('select * from Categories where ParentId = %d', [qryCategory.FieldByName('ID').AsInteger]));
          while not(tmpQuery.Eof) do
          begin
            TreeChild := TreeView1.Items.AddChild(TreeParent, tmpQuery.FieldByName('CategoryName').AsString);

            BuildTree(TreeChild, tmpQuery.FieldByName('ID').AsInteger);

            tmpQuery.Next;
          end;
          tmpQuery.Close;
        end;
        qryCategory.Next;
      end;
    end else
    begin
      // Add child nodes
      tmpQuery.Close;
      tmpQuery.Open(format('select id, CategoryName from Categories where ParentId = %d', [AParentId]));
      while not(tmpQuery.Eof) do
      begin
        TreeChild := TreeView1.Items.AddChild(ATreeNode, tmpQuery.FieldByName('CategoryName').AsString);

        BuildTree(TreeChild, tmpQuery.FieldByName('Id').AsInteger);

        tmpQuery.Next;
      end;
      tmpQuery.Close;
    end;
  finally
    tmpQuery.Free;
  end;
end;
```
