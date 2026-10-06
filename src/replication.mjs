const COLLECTIONS=new Set(['players','zombies','walls','resources','workers','drops','fallen','communities','obstacles']);
const ENTITY=Symbol('entities'),RECORD=Symbol('record');
export const createEncodingContext=()=>({tokens:new WeakMap(),rows:new WeakMap(),views:new WeakMap()});
function token(value,context){
 if(value&&typeof value==='object'){
  if(!context.tokens.has(value))context.tokens.set(value,JSON.stringify(value));
  return context.tokens.get(value);
 }
 return typeof value==='string'?'s:'+value:typeof value==='number'&&!Number.isFinite(value)?null:value;
}
function fieldsFor(value,previous,context){
 if(context.rows.has(value))return context.rows.get(value);
 let result=previous;
 for(const [key,item] of Object.entries(value)){
  if(item===undefined)continue;
  const text=token(item,context);
  if(!previous||!previous.has(key)||previous.get(key)!==text){if(result===previous)result=new Map(previous);result.set(key,text);}
 }
 if(previous)for(const key of previous.keys())if(!Object.hasOwn(value,key)||value[key]===undefined){if(result===previous)result=new Map(previous);result.delete(key);}
 result=result||new Map();context.rows.set(value,result);return result;
}
function capture(state,previous,context){
 const fields=new Map(),entities=new Map(),records=new Map();
 for(const [key,value] of Object.entries(state)){
  if(value===undefined)continue;
  if(COLLECTIONS.has(key)&&Array.isArray(value)&&value.every(item=>typeof item?.id==='string')&&new Set(value.map(item=>item.id)).size===value.length){
   const prior=previous?.entities.get(key),rows=new Map();
   for(const item of value)rows.set(item.id,fieldsFor(item,prior?.rows.get(item.id),context));
   entities.set(key,{order:value.map(item=>item.id),rows});fields.set(key,ENTITY);
  }else if(value&&typeof value==='object'&&!Array.isArray(value)){
   records.set(key,fieldsFor(value,previous?.records.get(key),context));fields.set(key,RECORD);
  }else fields.set(key,token(value,context));
 }
 return {fields,entities,records};
}
function changes(value,current,prior){
 const patch={set:{},remove:[]};
 for(const [key,text] of current)if(!prior||!prior.has(key)||prior.get(key)!==text)patch.set[key]=value[key];
 if(prior)for(const key of prior.keys())if(!current.has(key))patch.remove.push(key);
 return patch;
}
export class DeltaEncoder{
 constructor(){this.sequence=0;this.previous=null;}
 encode(state,context=createEncodingContext()){
  const next=capture(state,this.previous,context),seq=++this.sequence;
  if(!this.previous||seq%100===0){this.previous=next;return {wire:1,seq,state};}
  const message={wire:1,seq,base:seq-1,set:{},remove:[],entities:{},objects:{}};
  for(const key of this.previous.fields.keys())if(!next.fields.has(key))message.remove.push(key);
  for(const [key,value] of Object.entries(state)){
   if(!next.fields.has(key))continue;
   const current=next.entities.get(key),prior=this.previous.entities.get(key);
   if(current&&prior){
    const patch={upsert:[],remove:[]};
    for(const id of prior.rows.keys())if(!current.rows.has(id))patch.remove.push(id);
    for(const item of value){
     const fields=current.rows.get(item.id),old=prior.rows.get(item.id);
     if(fields!==old)patch.upsert.push({id:item.id,...changes(item,fields,old)});
    }
    if(current.order.length!==prior.order.length||current.order.some((id,i)=>id!==prior.order[i]))patch.order=current.order;
    if(patch.upsert.length||patch.remove.length||patch.order)message.entities[key]=patch;
   }else if(next.records.has(key)&&this.previous.records.has(key)){
    const fields=next.records.get(key),old=this.previous.records.get(key);
    if(fields!==old)message.objects[key]=changes(value,fields,old);
   }else if(!this.previous.fields.has(key)||next.fields.get(key)!==this.previous.fields.get(key)||next.fields.get(key)===ENTITY||next.fields.get(key)===RECORD)message.set[key]=value;
  }
  this.previous=next;return message;
 }
}

// Reference decoder for protocol tests and load clients. Inputs are server frames.
export function applyFrame(previous,sequence,frame){
 if(frame.wire!==1||!Number.isSafeInteger(frame.seq))throw Error('Formato de replicación inválido');
 if(frame.state)return {state:structuredClone(frame.state),sequence:frame.seq};
 if(!previous||frame.base!==sequence||frame.seq!==sequence+1)throw Error('Falta un estado; reconecta para sincronizar');
 const state=structuredClone(previous);
 for(const key of frame.remove)delete state[key];
 Object.assign(state,frame.set);
 for(const [key,patch] of Object.entries(frame.objects||{})){for(const field of patch.remove)delete state[key][field];Object.assign(state[key],patch.set);}
 for(const [key,patch] of Object.entries(frame.entities)){
  const rows=new Map(state[key].map(item=>[item.id,item]));
  for(const id of patch.remove)rows.delete(id);
  for(const change of patch.upsert){const item=rows.get(change.id)||{id:change.id};for(const field of change.remove)delete item[field];Object.assign(item,change.set);rows.set(change.id,item);}
  const order=patch.order||[...rows.keys()];
  if(order.some(id=>!rows.has(id)))throw Error('Colección incompleta');
  state[key]=order.map(id=>rows.get(id));
 }
 return {state,sequence:frame.seq};
}
