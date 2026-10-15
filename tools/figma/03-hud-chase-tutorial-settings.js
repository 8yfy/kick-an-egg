// Batch 03 for the Figma MCP use_figma tool (fileKey VDqe1QM0L4jWzGavOuVQe7, page "Components").
// Blocked on 2026-10-13 by the Starter-plan MCP call limit; run it unchanged when calls are available again.
const FONT={family:'Fredoka One',style:'Regular'},NOTE={family:'Inter',style:'Regular'},NOTEB={family:'Inter',style:'Semi Bold'};
await Promise.all([figma.loadFontAsync(FONT),figma.loadFontAsync(NOTE),figma.loadFontAsync(NOTEB)]);
const P={}; for(const s of await figma.getLocalPaintStylesAsync()) P[s.name]=s;
const T={}; for(const s of await figma.getLocalTextStylesAsync()) T[s.fontSize]=s;
const get=id=>figma.getNodeByIdAsync(id);
const hex=h=>({r:parseInt(h.slice(0,2),16)/255,g:parseInt(h.slice(2,4),16)/255,b:parseInt(h.slice(4,6),16)/255});
const solid=(h,o=1)=>({type:'SOLID',color:hex(h),opacity:o});
const grad=(st,o=1,hz=false)=>({type:'GRADIENT_LINEAR',gradientTransform:hz?[[1,0,0],[0,1,0]]:[[0,1,0],[-1,0,1]],gradientStops:st.map((c,i)=>({position:i/(st.length-1),color:{...hex(c),a:1}})),opacity:o});
async function text(parent,str,size,o={}){const t=figma.createText(); t.fontName=FONT; t.fontSize=size; t.characters=str; if(T[size]) await t.setTextStyleIdAsync(T[size].id); if(o.fill) t.fills=[o.fill]; else if(o.style) await t.setFillStyleIdAsync(P[o.style].id); else t.fills=[solid(o.color||'FFFFFF')]; const sw=o.stroke===undefined?Math.max(2,Math.floor(size/11)):o.stroke; if(sw>0){t.strokes=[solid('080A10')]; t.strokeWeight=sw; try{t.strokeAlign='OUTSIDE'}catch(e){} try{t.strokeJoin='ROUND'}catch(e){}} if(o.name) t.name=o.name; if(parent) parent.appendChild(t); return t;}
async function note(parent,str,w,o={}){const t=figma.createText(); t.fontName=o.bold?NOTEB:NOTE; t.fontSize=o.size||16; t.characters=str; t.fills=[solid(o.color||'B8C0D4')]; if(parent) parent.appendChild(t); if(w){t.resize(w,20); t.textAutoResize='HEIGHT';} return t;}
function rect(parent,name,x,y,w,h,fill,r=0){const n=figma.createRectangle(); n.name=name; n.resize(w,h); n.fills=fill?[fill]:[]; n.cornerRadius=r; parent.appendChild(n); n.x=x; n.y=y; return n;}
function frame(parent,name,x,y,w,h,o={}){const f=figma.createFrame(); f.name=name; f.resize(w,h); f.fills=o.fill?[o.fill]:[]; if(o.r!=null) f.cornerRadius=o.r; f.clipsContent=!!o.clip; if(o.stroke){f.strokes=[solid(o.sc||'080A10',o.so??1)]; f.strokeWeight=o.stroke; f.strokeAlign=o.sa||'OUTSIDE';} if(parent) parent.appendChild(f); f.x=x; f.y=y; return f;}
function inst(parent,comp,w,h,x,y){const i=comp.createInstance(); parent.appendChild(i); i.resize(w,h); i.x=x; i.y=y; return i;}
function centerText(t,w,h,x0=0,y0=0){t.textAlignHorizontal='CENTER'; t.resize(w,t.height); t.textAutoResize='HEIGHT'; t.x=x0; t.y=y0+(h-t.height)/2;}
function rot(n,deg){const a=deg*Math.PI/180,c=Math.cos(a),s=Math.sin(a),w=n.width,h=n.height,cx=n.x+w/2,cy=n.y+h/2; n.relativeTransform=[[c,s,cx-c*w/2-s*h/2],[-s,c,cy+s*w/2-c*h/2]];}
function layoutSet(cs,cols,w,h,gx,gy){const pad=28; cs.children.forEach((ch,i)=>{ch.x=pad+(i%cols)*(w+gx); ch.y=pad+Math.floor(i/cols)*(h+gy);}); let mx=0,my=0; for(const ch of cs.children){mx=Math.max(mx,ch.x+ch.width); my=Math.max(my,ch.y+ch.height);} cs.resizeWithoutConstraints(mx+pad,my+pad);}
const STUDS=await get('1:73');
function studs(parent,w,h,op){const i=STUDS.createInstance(); parent.appendChild(i); i.x=0; i.y=0; i.resize(w,h); i.opacity=op; i.name='Studs'; i.constraints={horizontal:'STRETCH',vertical:'STRETCH'}; return i;}
const ART={}; for(const [k,id] of [['hud_eggs','1:78'],['hud_pets','1:79']]) ART[k]=await get(id);
const ICON={}; for(const [k,id] of [['Pointer','1:121'],['Checker','1:133'],['Warning','1:138'],['Front','1:141'],['Egg','1:145'],['House','1:148'],['HomeArrow','1:152'],['Straight','1:163'],['Down','1:167'],['Curved','1:173']]) ICON[k]=await get(id);
const CLOSE=await get('1:709'); const closeDefault=CLOSE.children.find(c=>c.name==='State=Default');

// fix overflowing sets on the kick board
layoutSet(await get('2:725'),3,400,120,40,30);
layoutSet(await get('2:734'),2,580,160,30,10);

for(const n of [...figma.currentPage.children]) if(['Board · Bars, panels & settings','Board · Egg-running HUD','Board · Tutorial kit'].includes(n.name)) n.remove();
let BX=Math.max(...figma.currentPage.children.map(n=>n.x+n.width))+120;
async function board(title,desc,w){const b=figma.createAutoLayout('VERTICAL'); b.name='Board · '+title; figma.currentPage.appendChild(b); b.resize(w,100); b.primaryAxisSizingMode='AUTO'; b.counterAxisSizingMode='FIXED'; b.paddingLeft=48; b.paddingRight=48; b.paddingTop=48; b.paddingBottom=48; b.itemSpacing=28; b.fills=[solid('1E2130')]; b.cornerRadius=28; b.x=BX; b.y=0; BX+=w+120; await text(b,title,56,{stroke:5}); if(desc) await note(b,desc,w-96,{size:18}); return b;}
function wrapRow(b,w){const r=figma.createAutoLayout('HORIZONTAL'); r.name='Row'; b.appendChild(r); r.resize(w,10); r.primaryAxisSizingMode='FIXED'; r.counterAxisSizingMode='AUTO'; r.layoutWrap='WRAP'; r.itemSpacing=40; r.counterAxisSpacing=40; r.fills=[]; return r;}
async function cell(row,caption){const c=figma.createAutoLayout('VERTICAL'); c.name='Cell'; row.appendChild(c); c.itemSpacing=14; c.fills=[]; await note(c,caption,null,{bold:true,color:'E6EAF5',size:16}); return c;}

// ---------- progress bars (Ui.progress)
const pbC=[];
for(const [sty,pair] of [['Gold','Button/Gold'],['Lime','Button/Lime'],['Danger','Button/Red'],['Cyan','Button/Cyan']]){const c=figma.createComponent(); c.name=`Style=${sty}`; c.resize(360,34); c.cornerRadius=6; c.clipsContent=true; c.fills=[solid('171B26')]; c.strokes=[solid('080A10')]; c.strokeWeight=3; c.strokeAlign='OUTSIDE'; const f=rect(c,'Fill',0,0,223,34,null,6); await f.setFillStyleIdAsync(P[pair].id); rect(c,'Highlight',3,2,217,12,solid('FFFFFF',0.25),4); const t=await text(c,'62%',24,{stroke:3,name:'Value'}); centerText(t,360,34); pbC.push(c);}

// ---------- window panel (Window.luau / Modal shell): body + header (gradient, studs, two strips, shine) + red close
const winC=[];
for(const [hd,title,icon,pairName] of [['Inventory','INVENTORY','hud_pets','Header/Inventory'],['Settings','Settings',null,'Header/Settings']]){const W=960,H=640,HH=88; const c=figma.createComponent(); c.name=`Header=${hd}`; c.resize(W,H); c.cornerRadius=12; c.clipsContent=true; await c.setFillStyleIdAsync(P['Surface/Body'].id); c.strokes=[solid('080A10')]; c.strokeWeight=5; c.strokeAlign='OUTSIDE'; studs(c,W,H,0.1);
 const h=frame(c,'Header',0,0,W,HH,{clip:true}); await h.setFillStyleIdAsync(P[pairName].id); h.constraints={horizontal:'STRETCH',vertical:'MIN'}; studs(h,W,HH,0.14);
 for(const [i,w] of [[0,70],[1,34]]){const s=rect(h,'Strip'+(i+1),W*(0.62+i*0.06)-w/2,HH/2-150,w,300,solid('FFFFFF',0.18)); rot(s,-28); s.constraints={horizontal:'SCALE',vertical:'MIN'};}
 rect(h,'Shine',0,0,W,4,solid('FFFFFF',0.25)).constraints={horizontal:'STRETCH',vertical:'MIN'};
 let x=22; if(icon){const ic=inst(h,ART[icon],64,64,18,12); ic.name='Icon'; x=94;} const t=await text(h,title,52,{stroke:4,name:'Title'}); t.x=x; t.y=(HH-t.height)/2;
 const cl=inst(c,closeDefault,64,64,W-64-12,12); cl.name='Close'; cl.constraints={horizontal:'MAX',vertical:'MIN'};
 const b=frame(c,'Body',24,HH+16,W-48,H-HH-32,{}); b.constraints={horizontal:'STRETCH',vertical:'STRETCH'};
 winC.push(c);}

// ---------- egg-running HUD
const quest=figma.createComponent(); quest.name='Chase/Eggs Secured'; quest.layoutMode='VERTICAL'; quest.primaryAxisSizingMode='AUTO'; quest.counterAxisSizingMode='AUTO'; quest.counterAxisAlignItems='CENTER'; quest.itemSpacing=6; quest.fills=[];
const qt=await text(quest,'Eggs secured',44,{stroke:4,name:'Title'});
const qrow=figma.createAutoLayout('HORIZONTAL'); qrow.name='Row'; quest.appendChild(qrow); qrow.itemSpacing=8; qrow.counterAxisAlignItems='CENTER'; qrow.fills=[];
const qi=ART['hud_eggs'].createInstance(); qrow.appendChild(qi); qi.resize(48,48); qi.name='Icon';
const qb=frame(qrow,'Bar',0,0,380,30,{r:15,stroke:4,clip:true}); qb.fills=[solid('171B26')]; const qf=rect(qb,'Fill',0,0,228,30,null,15); await qf.setFillStyleIdAsync(P['Button/Gold'].id); rect(qb,'Highlight',4,3,220,10,solid('FFFFFF',0.3),5); const qc=await text(qb,'3 / 5',20,{stroke:3,name:'Count'}); centerText(qc,380,30);
const qtk=quest.addComponentProperty('Title','TEXT','Eggs secured'); qt.componentPropertyReferences={characters:qtk}; const qck=quest.addComponentProperty('Count','TEXT','3 / 5'); qc.componentPropertyReferences={characters:qck};

const zone=figma.createComponent(); zone.name='Chase/Zone Progress'; zone.resize(470,96); zone.fills=[]; zone.clipsContent=false;
const zt=frame(zone,'Track',28,6,436,34,{r:17,stroke:4,clip:true}); zt.fills=[solid('171B26')]; studs(zt,436,34,0.1); rect(zt,'Fill',0,0,82,34,grad(['FFB27A','FF641E']),17); rect(zt,'Highlight',6,3,70,10,solid('FFFFFF',0.32),5); inst(zt,ICON['Checker'],28,22,436-36,6).name='Finish';
const zp=await text(zt,'15%',22,{stroke:3,name:'Percent'}); centerText(zp,436,34);
const zc=frame(zone,'Zone chip',0,0,46,46,{r:23,stroke:4}); zc.fills=[grad(['FFB27A','FF641E'])]; const zn=await text(zc,'9',24,{stroke:3,name:'ZoneNumber'}); centerText(zn,46,46);
const zm=inst(zone,ICON['Egg'],24,30,28+82-12,8); zm.name='Egg marker';
const zl=frame(zone,'Name plate',85,52,300,40,{r:10,stroke:4}); zl.fills=[solid('171B26')]; rect(zl,'Accent',0,36,300,4,solid('FF641E')); const zname=await text(zl,'VOLCANO',24,{stroke:3,name:'ZoneName'}); centerText(zname,300,38);
const znk=zone.addComponentProperty('Zone name','TEXT','VOLCANO'); zname.componentPropertyReferences={characters:znk}; const zpk=zone.addComponentProperty('Percent','TEXT','15%'); zp.componentPropertyReferences={characters:zpk}; const zck=zone.addComponentProperty('Zone number','TEXT','9'); zn.componentPropertyReferences={characters:zck};

const avC=[];
for(const [st,k,dist,fillN,stroke] of [['Safe',0.78,'117 studs','Button/Lime','080A10'],['Close',0.42,'63 studs','Button/Gold','080A10'],['Danger',0.14,'21 studs','Button/Red','FF5444']]){const W=470,H=80; const c=figma.createComponent(); c.name=`State=${st}`; c.resize(W,H); c.cornerRadius=12; c.clipsContent=false; c.fills=[solid('171B26',0.92)]; c.strokes=[solid(stroke)]; c.strokeWeight=5; c.strokeAlign='OUTSIDE'; const cl=frame(c,'Studs clip',0,0,W,H,{r:12,clip:true}); studs(cl,W,H,0.1);
 inst(c,ICON['Warning'],46,41,14,18).name='Warning';
 const tt=await text(c,'AVALANCHE',20,{stroke:3,color:'FF6E50',name:'Title'}); tt.x=74; tt.y=8;
 const dt=await text(c,dist,20,{stroke:3,color:st==='Danger'?'FF5444':'FFFFFF',name:'Distance'}); dt.textAlignHorizontal='RIGHT'; dt.resize(140,dt.height); dt.textAutoResize='HEIGHT'; dt.x=W-14-140; dt.y=8;
 const tr=frame(c,'Track',74,42,382,24,{r:12,stroke:3,clip:true}); tr.fills=[solid('0F1219')]; const ramp=rect(tr,'Danger ramp',0,0,382,24,null); await ramp.setFillStyleIdAsync(P['Chase/Danger Ramp'].id); ramp.opacity=0.18;
 const gf=rect(tr,'Gap',0,0,Math.round(382*k),24,null,12); await gf.setFillStyleIdAsync(P[fillN].id); rect(tr,'Highlight',4,3,Math.max(0,Math.round(382*k)-8),7,solid('FFFFFF',0.3),3);
 inst(tr,ICON['Front'],18,23,1,0).name='Avalanche front';
 inst(c,ICON['Egg'],24,30,74+Math.round(382*k)-12,39).name='Your egg';
 avC.push(c);}

const run=figma.createComponent(); run.name='Chase/Run Banner'; run.resize(620,210); run.fills=[]; run.clipsContent=false;
const rt=await text(run,'RUN!',120,{stroke:9,fill:grad(['FFB09A','FF4A3A','C2101C']),name:'Title'}); rt.x=(620-rt.width)/2; rt.y=0;
const rpl=figma.createAutoLayout('HORIZONTAL'); run.appendChild(rpl); rpl.name='Sub pill'; rpl.paddingLeft=18; rpl.paddingRight=18; rpl.paddingTop=6; rpl.paddingBottom=6; rpl.itemSpacing=10; rpl.counterAxisAlignItems='CENTER'; rpl.cornerRadius=18; rpl.fills=[solid('080A10',0.6)];
const wi=ICON['Warning'].createInstance(); rpl.appendChild(wi); wi.resize(30,27); await text(rpl,'AVALANCHE INCOMING!',24,{stroke:3});
rpl.x=(620-rpl.width)/2; rpl.y=rt.y+rt.height+4;

const home=figma.createComponent(); home.name='Chase/Home Indicator'; home.resize(170,168); home.fills=[]; home.clipsContent=false;
const dial=frame(home,'Dial',33,0,104,104,{r:52,stroke:5,clip:true}); dial.fills=[solid('171B26',0.88)]; studs(dial,104,104,0.1); const ha=inst(dial,ICON['HomeArrow'],60,64,22,20); ha.name='Arrow (rotates)'; rot(ha,-30);
const hp=figma.createAutoLayout('HORIZONTAL'); home.appendChild(hp); hp.name='Label'; hp.paddingLeft=12; hp.paddingRight=14; hp.paddingTop=6; hp.paddingBottom=6; hp.itemSpacing=8; hp.counterAxisAlignItems='CENTER'; hp.cornerRadius=12; hp.fills=[solid('171B26')]; hp.strokes=[solid('080A10')]; hp.strokeWeight=4; hp.strokeAlign='OUTSIDE';
const hh=ICON['House'].createInstance(); hp.appendChild(hh); hh.resize(28,27); const hl=await text(hp,'HOME 120',22,{stroke:3,name:'Distance'}); hp.x=(170-hp.width)/2; hp.y=116;
const hk=home.addComponentProperty('Distance','TEXT','HOME 120'); hl.componentPropertyReferences={characters:hk};

// ---------- tutorial kit
const insC=[];
for(const tail of ['None','Down','Up']){const c=figma.createComponent(); c.name=`Tail=${tail}`; c.layoutMode='HORIZONTAL'; c.primaryAxisSizingMode='AUTO'; c.counterAxisSizingMode='AUTO'; c.counterAxisAlignItems='CENTER'; c.paddingLeft=10; c.paddingRight=20; c.paddingTop=9; c.paddingBottom=9; c.itemSpacing=12; c.cornerRadius=16; c.fills=[solid('171B26',0.94)]; c.strokes=[solid('080A10')]; c.strokeWeight=4; c.strokeAlign='OUTSIDE'; c.clipsContent=false;
 const chip=figma.createFrame(); chip.name='Step'; c.appendChild(chip); chip.resize(36,36); chip.cornerRadius=18; await chip.setFillStyleIdAsync(P['Button/Gold'].id); chip.strokes=[solid('080A10')]; chip.strokeWeight=3; const sn=await text(chip,'2',20,{stroke:2,name:'StepLabel'}); centerText(sn,36,36);
 await text(c,'Press KICK!',26,{stroke:3,name:'Message'});
 if(tail!=='None'){const tl=figma.createNodeFromSvg(`<svg width="30" height="18" viewBox="0 0 30 18" xmlns="http://www.w3.org/2000/svg"><path d="${tail==='Down'?'M2 1L15 16L28 1':'M2 17L15 2L28 17'}" fill="#171B26" stroke="#080A10" stroke-width="4" stroke-linejoin="round"/></svg>`); c.appendChild(tl); tl.layoutPositioning='ABSOLUTE'; tl.name='Tail'; tl.x=(c.width-30)/2; tl.y=tail==='Down'?c.height-1:-17;}
 insC.push(c);}
const hiC=[];
for(const st of ['Static','Pulse']){const c=figma.createComponent(); c.name=`State=${st}`; c.resize(260,100); c.fills=[]; c.cornerRadius=14; c.strokes=[solid('FFD746')]; c.strokeWeight=5; c.strokeAlign='OUTSIDE'; c.clipsContent=false; const inner=frame(c,'Inner edge',3,3,254,94,{r:11,stroke:2,sc:'FFFFFF',so:0.6,sa:'INSIDE'}); inner.constraints={horizontal:'STRETCH',vertical:'STRETCH'}; if(st==='Pulse'){const o=frame(c,'Pulse ring',-12,-12,284,124,{r:22,stroke:4,sc:'FFD746',so:0.35}); o.constraints={horizontal:'STRETCH',vertical:'STRETCH'};} hiC.push(c);}
const spot=figma.createComponent(); spot.name='Tutorial/Spotlight'; spot.resize(640,360); spot.fills=[]; spot.clipsContent=true;
const full=figma.createRectangle(); full.resize(640,360); full.fills=[solid('000000',0.42)]; spot.appendChild(full); const hole=figma.createRectangle(); hole.resize(220,110); hole.x=210; hole.y=170; hole.cornerRadius=18; spot.appendChild(hole); const dim=figma.subtract([full,hole],spot); dim.name='Dim (4 frames around the target in Roblox)';
const hb=hiC[1].createInstance(); spot.appendChild(hb); hb.resize(220,110); hb.x=210; hb.y=170;
const sa=inst(spot,ICON['Down'],50,74,295,82); sa.name='Arrow';
const si=insC[0].createInstance(); spot.appendChild(si); si.x=(640-si.width)/2; si.y=24;
const world=figma.createComponent(); world.name='Tutorial/World Marker'; world.layoutMode='VERTICAL'; world.primaryAxisSizingMode='AUTO'; world.counterAxisSizingMode='AUTO'; world.counterAxisAlignItems='CENTER'; world.itemSpacing=4; world.fills=[];
const wa=ICON['Down'].createInstance(); world.appendChild(wa); wa.resize(56,82); await text(world,'24 studs',20,{stroke:3,name:'Distance'});
const skip=figma.createComponent(); skip.name='Tutorial/Skip'; skip.layoutMode='HORIZONTAL'; skip.primaryAxisSizingMode='AUTO'; skip.counterAxisSizingMode='AUTO'; skip.paddingLeft=12; skip.paddingRight=12; skip.paddingTop=4; skip.paddingBottom=4; skip.cornerRadius=10; skip.fills=[solid('080A10',0.5)]; await text(skip,'SKIP TUTORIAL',17,{stroke:0,color:'D5DAE6'});

// ---------- settings rows (SettingsMenu: 92 px rows, 180x66 buttons)
const rowC=[];
for(const [kind,label,pairName,val] of [['Toggle On','Sound effects','Settings/On','ON'],['Toggle Off','Camera shake','Settings/Off','OFF'],['Volume','Music','Settings/Choice','100%'],['Choice','Sack effects','Settings/Choice','AUTO']]){const W=860,H=92; const c=figma.createComponent(); c.name=`Kind=${kind}`; c.resize(W,H); c.cornerRadius=18; c.clipsContent=false; await c.setFillStyleIdAsync(P['Settings/Row'].id); c.strokes=[solid('080A10')]; c.strokeWeight=3; c.strokeAlign='OUTSIDE'; const t=await text(c,label,34,{stroke:3,name:'Title'}); t.x=24; t.y=(H-t.height)/2; const b=frame(c,'Button',W-16-180,13,180,66,{r:12,stroke:4,clip:true}); await b.setFillStyleIdAsync(P[pairName].id); studs(b,180,66,0.16); rect(b,'Highlight',4,4,172,22,solid('FFFFFF',0.22),6); const bt=await text(b,val,34,{stroke:3,name:'Value'}); centerText(bt,180,66); b.constraints={horizontal:'MAX',vertical:'CENTER'}; rowC.push(c);}

// ---------- boards
const bb=await board('Bars, panels & settings','Ui.progress bars, the window shell (Window.luau / Modal: header gradient + studs + two diagonal strips + shine, 5 px border, red close) and SettingsMenu rows (92 px rows, 180×66 buttons). The Settings fix is already live (ScrollingFrame + UIListLayout + UIPadding, automatic canvas height); the previews show it.',1700);
const br=wrapRow(bb,1604);
let a1=await cell(br,'Progress Bar · Style'); const s1=figma.combineAsVariants(pbC,a1); s1.name='Progress Bar'; layoutSet(s1,2,360,34,30,24);
let a2=await cell(br,'Panel/Window · Header (resizable: header stretches, close pins right)'); const s2=figma.combineAsVariants(winC,a2); s2.name='Panel/Window'; layoutSet(s2,2,960,640,40,30);
let a3=await cell(br,'Settings/Row · Kind'); const s3=figma.combineAsVariants(rowC,a3); s3.name='Settings/Row'; layoutSet(s3,1,860,92,30,20);
const cb=await board('Egg-running HUD','Same card language as the rest of the HUD (#171B26 cards, 4–5 px border, studs, Fredoka). Eggs Secured: quest title + egg icon + gold bar. Zone progress: native continuous bar in the zone accent colour (Config/Zones accent), number chip, egg marker riding the fill, finish flag, name plate (replaces the 5 stepped PNG frames). Avalanche: the bar is the GAP between the avalanche front (left) and your egg, green → gold → red, red border when close. Home: rotating lime arrow in a dial + HOME distance. All values stay live from the existing code.',1700);
const cr=wrapRow(cb,1604);
let b1=await cell(cr,'Chase/Eggs Secured'); b1.appendChild(quest);
let b2=await cell(cr,'Chase/Zone Progress'); b2.appendChild(zone);
let b3=await cell(cr,'Chase/Avalanche · State'); const s4=figma.combineAsVariants(avC,b3); s4.name='Chase/Avalanche'; layoutSet(s4,1,470,80,30,30);
let b4=await cell(cr,'Chase/Run Banner (warn phase)'); b4.appendChild(run);
let b5=await cell(cr,'Chase/Home Indicator'); b5.appendChild(home);
const tb=await board('Tutorial kit','Gold arrows (straight, curved, down) in the icon style, a tap/click pointer, a gold highlight border (pulse = second faint ring), a light spotlight (42% black with a rounded hole; built from 4 frames in Roblox, so input still reaches the game), a short instruction label with step chip and optional tail, a world marker (BillboardGui) and SKIP. Nothing blocks the player; text stays to a few words.',1700);
const trw=wrapRow(tb,1604);
let e1=await cell(trw,'Tutorial/Instruction · Tail'); const s5=figma.combineAsVariants(insC,e1); s5.name='Tutorial/Instruction'; s5.children.forEach((ch,i)=>{ch.x=28; ch.y=40+i*90;}); s5.resizeWithoutConstraints(Math.max(...s5.children.map(ch=>ch.width))+56,40+3*90);
const mk=s5.addComponentProperty('Message','TEXT','Press KICK!'), stk=s5.addComponentProperty('Step','TEXT','2'); for(const v of s5.children){const m=v.findOne(n=>n.name==='Message'); if(m) m.componentPropertyReferences={characters:mk}; const q=v.findOne(n=>n.name==='StepLabel'); if(q) q.componentPropertyReferences={characters:stk};}
let e2=await cell(trw,'Tutorial/Highlight Border · State'); const s6=figma.combineAsVariants(hiC,e2); s6.name='Tutorial/Highlight Border'; layoutSet(s6,2,260,100,60,30);
let e3=await cell(trw,'Tutorial/Spotlight (demo)'); e3.appendChild(spot);
let e4=await cell(trw,'Tutorial/World Marker'); e4.appendChild(world);
let e5=await cell(trw,'Tutorial/Skip'); e5.appendChild(skip);

await bb.screenshot({scale:0.4}); await cb.screenshot({scale:0.45}); await tb.screenshot({scale:0.45});
return {progress:s1.id,window:s2.id,windowV:Object.fromEntries(s2.children.map(c=>[c.name,c.id])),settingsRow:s3.id,rowV:Object.fromEntries(s3.children.map(c=>[c.name,c.id])),quest:quest.id,zone:zone.id,aval:s4.id,avalV:Object.fromEntries(s4.children.map(c=>[c.name,c.id])),run:run.id,home:home.id,instr:s5.id,instrV:Object.fromEntries(s5.children.map(c=>[c.name,c.id])),highlight:s6.id,highlightV:Object.fromEntries(s6.children.map(c=>[c.name,c.id])),spot:spot.id,world:world.id,skip:skip.id,pbV:Object.fromEntries(s1.children.map(c=>[c.name,c.id])),boards:{bars:bb.id,chase:cb.id,tut:tb.id}};
