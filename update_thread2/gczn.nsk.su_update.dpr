program gczn.nsk.su_update;

uses
  Forms,
  Unit2 in 'Unit2.pas' {Form2},
  RegExpr in 'RegExpr\RegExpr.pas',
  NativeXml in 'NativeXml\NativeXml.pas',
  DetailedRTTI in 'otl\DetailedRTTI.pas',
  DSiWin32 in 'otl\DSiWin32.pas',
  GpLists in 'otl\GpLists.pas',
  GpLockFreeQueue in 'otl\GpLockFreeQueue.pas',
  GpStringHash in 'otl\GpStringHash.pas',
  GpStuff in 'otl\GpStuff.pas',
  HVStringBuilder in 'otl\HVStringBuilder.pas',
  HVStringData in 'otl\HVStringData.pas',
  OtlCollections in 'otl\OtlCollections.pas',
  OtlComm in 'otl\OtlComm.pas',
  OtlCommBufferTest in 'otl\OtlCommBufferTest.pas',
  OtlCommon in 'otl\OtlCommon.pas',
  OtlCommon.Utils in 'otl\OtlCommon.Utils.pas',
  OtlContainerObserver in 'otl\OtlContainerObserver.pas',
  OtlContainers in 'otl\OtlContainers.pas',
  OtlDataManager in 'otl\OtlDataManager.pas',
  OtlEventMonitor in 'otl\OtlEventMonitor.pas',
  OtlHooks in 'otl\OtlHooks.pas',
  OtlLogger in 'otl\OtlLogger.pas',
  OtlParallel in 'otl\OtlParallel.pas',
  OtlRegister in 'otl\OtlRegister.pas',
  OtlSync in 'otl\OtlSync.pas',
  OtlTask in 'otl\OtlTask.pas',
  OtlTaskControl in 'otl\OtlTaskControl.pas',
  OtlThreadPool in 'otl\OtlThreadPool.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
