var ApplePay = {

    getAllowsApplePay: function(successCallback, errorCallback) {
        cordova.exec(
            successCallback,
            errorCallback,
            'ApplePay',
            'getAllowsApplePay',
            []
        );
    },
    
    setMerchantId: function(successCallback, errorCallback, merchantId) {
        cordova.exec(
            successCallback,
            errorCallback,
            'ApplePay',
            'setMerchantId',
            [merchantId]
        );
    },

    getStripeToken: function(successCallback, errorCallback, amount, name, cur) {
        cordova.exec(
            successCallback,
            errorCallback,
            'ApplePay',
            'getStripeToken',
            [amount, name, cur]
        );
    }
    
};

module.exports = ApplePay;
