Ext.define('Ext.ux.MyChildRequires', {
   // should get code complete here for MyBase config options
    uses: ['Ext.ux.MyChildRequiresUses'],
    myProp: '42',
    singleton: true,
    constructor: function(){
        Ext.define("Ext.ux.MyChildRequiresUses",{});
    }
});