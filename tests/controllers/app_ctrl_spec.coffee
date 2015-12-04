describe "AppCtrl", ->
  scope = undefined
  callbacks = undefined
  mockModalInstance = undefined

  beforeEach angular.mock.module("walletApp")

  beforeEach ->
    angular.mock.inject ($injector, $rootScope, $controller) ->
      Wallet = $injector.get("Wallet")
      MyWallet = $injector.get("MyWallet")

      Wallet.accounts = () -> [{},{}]

      mockModalInstance =
        result: then: (confirmCallback, cancelCallback) ->
          #Store the callbacks for later when the user clicks on the OK or Cancel button of the dialog
          @confirmCallBack = confirmCallback
          @cancelCallback = cancelCallback
          return
        close: (item) ->
          #The user clicked OK on the modal dialog, call the stored confirm callback with the selected item
          @result.confirmCallBack item
          return
        dismiss: (type) ->
          #The user clicked cancel on the modal dialog, call the stored cancel callback
          @result.cancelCallback type
          return

      scope = $rootScope.$new()

      $controller "AppCtrl",
        $scope: scope,
        $stateParams: {}

  it "should redirect to login if not logged in",  inject((Wallet, $state) ->
    expect(scope.status.isLoggedIn).toBe(false)
    spyOn($state, "go")
    scope.$broadcast("$stateChangeSuccess", {name: "home"})
    expect($state.go).toHaveBeenCalledWith("public.login")
  )

  it "should not redirect to login if logged in",  inject((Wallet, $state) ->
    Wallet.status.isLoggedIn = true
    expect(scope.status.isLoggedIn).toBe(true)
    spyOn($state, "go")
    scope.$broadcast("$stateChangeSuccess", {name: "home"})
    expect($state.go).not.toHaveBeenCalled()

  )

  it "should open a popup to send",  inject(($uibModal) ->
    spyOn($uibModal, "open")
    scope.send()
    expect($uibModal.open).toHaveBeenCalled()
  )

  it "should open a popup to request",  inject(($uibModal) ->
    spyOn($uibModal, "open")
    scope.request()
    expect($uibModal.open).toHaveBeenCalled()
  )

  describe "HD upgrade", ->
    beforeEach ->
      callbacks =  {
        proceed: () ->
          console.log "proceed"
      }
      spyOn(callbacks, "proceed")

    it "should show modal if HD upgrade is needed", inject(($uibModal) ->
      spyOn($uibModal, "open").and.callThrough()
      scope.$broadcast("needsUpgradeToHD", callbacks.proceed)
      expect($uibModal.open).toHaveBeenCalled()
    )

  describe "redeem from email", ->
    it "should proceed after login", inject((Wallet, $rootScope, $timeout, $uibModal) ->

      spyOn($uibModal, 'open').and.returnValue(mockModalInstance)

      # Fulfill necessary conditions befor goal can be checked
      Wallet.status.isLoggedIn = true
      Wallet.settings = { currency: true, btcCurrency: true }
      Wallet.goal.claim = {code: "abcd", balance: 100000}

      $rootScope.$digest()
      $timeout.flush() # Modal won't open otherwise

      expect($uibModal.open).toHaveBeenCalled()
    )
