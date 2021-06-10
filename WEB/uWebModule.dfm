object WebModule1: TWebModule1
  OldCreateOrder = False
  Actions = <
    item
      MethodType = mtPost
      Name = 'WebActionItemPost'
      PathInfo = '/ProcessPost'
      OnAction = WebModule1WebActionItemPostAction
    end
    item
      Default = True
      MethodType = mtGet
      Name = 'WebActionItemDefault'
      PathInfo = '/'
      OnAction = WebModule1WebActionItemDefaultAction
    end>
  Height = 150
  Width = 410
  object HTTPSoapDispatcher1: THTTPSoapDispatcher
    Dispatcher = HTTPSoapPascalInvoker1
    WebDispatch.PathInfo = 'soap*'
    Left = 72
    Top = 24
  end
  object HTTPSoapPascalInvoker1: THTTPSoapPascalInvoker
    Converter.Options = [soSendMultiRefObj, soTryAllSchema, soRootRefNodesToBody, soCacheMimeResponse, soUTF8EncodeXML]
    Left = 160
    Top = 24
  end
  object WSDLHTMLPublish1: TWSDLHTMLPublish
    WebDispatch.MethodType = mtAny
    WebDispatch.PathInfo = 'wsdl*'
    Left = 240
    Top = 24
  end
end
