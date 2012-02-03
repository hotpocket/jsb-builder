Ext.define('Ext.ux.MyChild', 
{
    extend: 'Ext.ux.MyBase',
    requires: 'Ext.ux.MyChildRequires'
   // should get code complete here for MyBase config options
},function(){
    Ext.ux.MyChildRequires.myProp;
});
