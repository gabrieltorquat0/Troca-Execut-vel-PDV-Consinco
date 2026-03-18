object DmMySql: TDmMySql
  Height = 480
  Width = 640
  object FDPhysMySQLDriverLink1: TFDPhysMySQLDriverLink
    Left = 120
    Top = 88
  end
  object MemResultado: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 304
    Top = 224
  end
end
