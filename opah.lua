--[[
    Opah Hub - by Nadiel x Claude
    Game: Lari dari Rumah Opah
    Fitur: Auto Key + Buka Pintu, Cari Kertas + Kode, Daftar Teleport
    Catatan: nama objek di game ditebak lewat kata kunci (key/kunci, kertas/paper, pintu/door).
    Kalau tidak ketemu, tambahkan kata kunci sendiri di tab Settings.
]]

local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Players=game:GetService("Players")
local lp=Players.LocalPlayer
local pg=lp:WaitForChild("PlayerGui")
if _G.OPAH then pcall(_G.OPAH) end

local alive=true
local S={auto=false,back=true}
local conns={}
local function bind(sig,fn) local c=sig:Connect(fn) conns[#conns+1]=c return c end
local function isPress(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch end

local C={
	bg=Color3.fromRGB(10,14,26), side=Color3.fromRGB(13,19,36), row=Color3.fromRGB(20,28,50),
	acc=Color3.fromRGB(0,140,255), txt=Color3.fromRGB(232,238,250), sub=Color3.fromRGB(128,142,170),
	off=Color3.fromRGB(52,64,92), line=Color3.fromRGB(30,50,95),
}

local function new(cls,props,parent)
	local o=Instance.new(cls)
	for k,v in pairs(props) do o[k]=v end
	o.Parent=parent
	return o
end
local function round(o,r) new("UICorner",{CornerRadius=UDim.new(0,r or 8)},o) end
local function label(parent,text,size,pos,sz,color,font,align)
	return new("TextLabel",{BackgroundTransparency=1,Text=text,TextSize=size,Position=pos,Size=sz,
		TextColor3=color or C.txt,Font=font or Enum.Font.Gotham,
		TextXAlignment=align or Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},parent)
end
local function hrp() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

----------------------------------------------------------------
-- DETEKSI OBJEK
----------------------------------------------------------------
local KEYK={"key","kunci"}
local EXK={"keyboard","monkey","turkey","keyhole","keypad"}
local PAPK={"paper","kertas","note","catatan","clue","petunjuk","kode","code","surat","letter"}
local DOORK={"door","pintu","gate","gerbang"}

local function has(n,keys)
	for _,k in ipairs(keys) do
		if n:find(k,1,true) then return true end
	end
	return false
end

local function kindOf(name)
	local n=name:lower()
	if has(n,KEYK) and not has(n,EXK) then return "Key" end
	if has(n,PAPK) then return "Kertas" end
	if has(n,DOORK) then return "Pintu" end
	return nil
end

local function posOf(o)
	if o:IsA("Model") then
		local ok,cf=pcall(function() return o:GetPivot() end)
		if ok then return cf.Position end
	elseif o:IsA("BasePart") then
		return o.Position
	elseif o:IsA("Tool") then
		local h=o:FindFirstChild("Handle")
		if h then return h.Position end
	end
	return nil
end

local function interactive(o)
	for _,d in ipairs(o:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then return true end
	end
	return false
end

local items={Key={},Kertas={},Pintu={}}

local function scan()
	items={Key={},Kertas={},Pintu={}}
	for _,o in ipairs(workspace:GetDescendants()) do
		if o:IsA("BasePart") or o:IsA("Model") or o:IsA("Tool") then
			local k=kindOf(o.Name)
			if k and #items[k]<40 then
				local skip=false
				if o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") then skip=true end
				local a=o.Parent
				while not skip and a and a~=workspace do
					if kindOf(a.Name)==k or (a:IsA("Model") and a:FindFirstChildOfClass("Humanoid")) then skip=true end
					a=a.Parent
				end
				if not skip and k=="Pintu" and not interactive(o) then skip=true end
				if not skip and posOf(o) then table.insert(items[k],o) end
			end
		end
	end
end

local function sortByDist(list)
	local r=hrp()
	local out={}
	for _,o in ipairs(list) do if o.Parent then out[#out+1]=o end end
	if r then
		local me=r.Position
		table.sort(out,function(a,b)
			local pa,pb=posOf(a),posOf(b)
			if not (pa and pb) then return false end
			return (pa-me).Magnitude<(pb-me).Magnitude
		end)
	end
	return out
end

----------------------------------------------------------------
-- AKSI: TELEPORT & INTERAKSI
----------------------------------------------------------------
local function tpPos(pos)
	local r=hrp()
	if not r then return false end
	r.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
	r.AssemblyLinearVelocity=Vector3.zero
	return true
end

local function touchAll(o)
	local r=hrp()
	if not (r and firetouchinterest) then return end
	local parts={}
	if o:IsA("BasePart") then
		parts[1]=o
	else
		for _,d in ipairs(o:GetDescendants()) do
			if d:IsA("BasePart") then
				parts[#parts+1]=d
				if #parts>=6 then break end
			end
		end
	end
	for _,p in ipairs(parts) do
		pcall(function()
			firetouchinterest(r,p,0)
			firetouchinterest(r,p,1)
		end)
	end
end

local function interact(o)
	local list={o}
	for _,d in ipairs(o:GetDescendants()) do list[#list+1]=d end
	if o.Parent and o.Parent~=workspace then
		for _,d in ipairs(o.Parent:GetChildren()) do list[#list+1]=d end
	end
	for _,d in ipairs(list) do
		if d:IsA("ProximityPrompt") then
			pcall(function()
				d.HoldDuration=0
				d.RequiresLineOfSight=false
				d.MaxActivationDistance=math.max(d.MaxActivationDistance,15)
			end)
			if fireproximityprompt then pcall(fireproximityprompt,d) end
		elseif d:IsA("ClickDetector") and fireclickdetector then
			pcall(fireclickdetector,d)
		end
	end
	touchAll(o)
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
local gui=new("ScreenGui",{Name="OpahHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=999})
if not pcall(function() gui.Parent=(gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then gui.Parent=pg end

local W,H=420,260
local main=new("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,Active=true,ClipsDescendants=true},gui)
round(main,12)
new("UIStroke",{Color=C.line,Thickness=1},main)

local head=new("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1},main)
label(head,"▲",18,UDim2.new(0,14,0,0),UDim2.new(0,24,1,0),C.acc,Enum.Font.GothamBold)
label(head,"Opah Hub",14,UDim2.new(0,42,0,6),UDim2.new(0,200,0,18),C.txt,Enum.Font.GothamBold)
label(head,"by Nadiel x Claude",11,UDim2.new(0,42,0,24),UDim2.new(0,200,0,14),C.sub)

local function headBtn(text,x)
	return new("TextButton",{Text=text,TextSize=16,Font=Enum.Font.GothamBold,TextColor3=C.sub,BackgroundTransparency=1,
		Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,x,0,7)},head)
end
local bMin=headBtn("–",-72)
local bClose=headBtn("X",-38)

local body=new("Frame",{Position=UDim2.new(0,0,0,44),Size=UDim2.new(1,0,1,-44),BackgroundTransparency=1},main)
local side=new("Frame",{Size=UDim2.new(0,110,1,0),BackgroundColor3=C.side,BorderSizePixel=0},body)
local tabList=new("Frame",{Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1},side)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},tabList)
new("UIPadding",{PaddingTop=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)},tabList)
local statusLbl=label(side,"Siap",10,UDim2.new(0,8,1,-34),UDim2.new(1,-12,0,30),C.sub)
statusLbl.TextWrapped=true
local function setStatus(t) statusLbl.Text=t end

local content=new("Frame",{Position=UDim2.new(0,110,0,0),Size=UDim2.new(1,-110,1,0),BackgroundTransparency=1},body)

-- geser jendela
do
	local drag,ds,sp
	head.InputBegan:Connect(function(i) if isPress(i) then drag,ds,sp=true,i.Position,main.Position end end)
	bind(UIS.InputChanged,function(i)
		if drag and isMove(i) then
			local d=i.Position-ds
			main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	bind(UIS.InputEnded,function(i) if isPress(i) then drag=false end end)
end

-- minimize jadi logo (geser, tap untuk buka)
local LS=52
local logo=new("TextButton",{Size=UDim2.new(0,LS,0,LS),Position=UDim2.new(0,20,0,60),BackgroundColor3=C.side,Text="▲",
	TextColor3=C.acc,TextSize=22,Font=Enum.Font.GothamBold,AutoButtonColor=false,Visible=false,Active=true},gui)
round(logo,LS/2)
new("UIStroke",{Color=C.acc,Thickness=2},logo)

local function clampXY(x,y,w,h)
	local cam=workspace.CurrentCamera
	local vs=cam and cam.ViewportSize or Vector2.new(800,400)
	return math.clamp(x,0,math.max(0,vs.X-w)),math.clamp(y,0,math.max(0,vs.Y-h))
end
local function showLogo()
	local p=main.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,LS,LS)
	logo.Position=UDim2.new(0,x,0,y)
	logo.Visible=true
	main.Visible=false
end
local function showMain()
	local p=logo.AbsolutePosition
	local x,y=clampXY(p.X,p.Y,W,H)
	main.Position=UDim2.new(0,x,0,y)
	main.Visible=true
	logo.Visible=false
end
bMin.MouseButton1Click:Connect(showLogo)

do
	local down,moved,ds,sp=false,false,nil,nil
	logo.InputBegan:Connect(function(i)
		if isPress(i) then down,moved,ds,sp=true,false,i.Position,logo.Position end
	end)
	bind(UIS.InputChanged,function(i)
		if down and isMove(i) then
			local d=i.Position-ds
			if d.Magnitude>8 then moved=true end
			if moved then
				local x,y=clampXY(sp.X.Offset+d.X,sp.Y.Offset+d.Y,LS,LS)
				logo.Position=UDim2.new(0,x,0,y)
			end
		end
	end)
	bind(UIS.InputEnded,function(i)
		if down and isPress(i) then
			down=false
			if not moved then showMain() end
		end
	end)
end

----------------------------------------------------------------
-- KOMPONEN UI
----------------------------------------------------------------
local pages,tabBtns={}, {}
local function addTab(name,order)
	local b=new("TextButton",{Text=name,TextSize=12,Font=Enum.Font.GothamMedium,TextColor3=C.sub,BackgroundColor3=C.row,
		BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),LayoutOrder=order,AutoButtonColor=false},tabList)
	round(b,8)
	local p=new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
		ScrollBarImageColor3=C.acc,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},content)
	new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},p)
	new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,12),PaddingBottom=UDim.new(0,8)},p)
	label(p,name,15,UDim2.new(),UDim2.new(1,0,0,22),C.txt,Enum.Font.GothamBold).LayoutOrder=0
	pages[name],tabBtns[name]=p,b
	b.MouseButton1Click:Connect(function()
		for n,pp in pairs(pages) do
			pp.Visible=(n==name)
			tabBtns[n].BackgroundTransparency=(n==name) and 0 or 1
			tabBtns[n].TextColor3=(n==name) and C.txt or C.sub
		end
	end)
	return p
end

local ord=0
local function base(page,title,desc)
	ord+=1
	local r=new("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.row,LayoutOrder=ord},page)
	round(r,8)
	label(r,title,13,UDim2.new(0,10,0,6),UDim2.new(1,-100,0,18),C.txt,Enum.Font.GothamMedium)
	label(r,desc or "",10,UDim2.new(0,10,0,25),UDim2.new(1,-100,0,14),C.sub)
	return r
end

local function toggle(page,title,desc,def,cb)
	local r=base(page,title,desc)
	local sw=new("Frame",{Size=UDim2.new(0,40,0,20),Position=UDim2.new(1,-50,0.5,-10)},r)
	round(sw,10)
	local kn=new("Frame",{Size=UDim2.new(0,16,0,16),BackgroundColor3=Color3.new(1,1,1)},sw)
	round(kn,8)
	local on=def
	local function paint()
		sw.BackgroundColor3=on and C.acc or C.off
		kn.Position=on and UDim2.new(1,-18,0,2) or UDim2.new(0,2,0,2)
	end
	paint()
	local function set(v,silent) on=v paint() if not silent then cb(on) end end
	new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},r).MouseButton1Click:Connect(function() set(not on) end)
	return set
end

local function button(page,title,desc,text,cb)
	local r=base(page,title,desc)
	local b=new("TextButton",{Text=text,TextSize=12,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
		BackgroundColor3=C.acc,Size=UDim2.new(0,76,0,26),Position=UDim2.new(1,-86,0.5,-13)},r)
	round(b,6)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end

local function textRow(page,title,desc,cb)
	local r=base(page,title,desc)
	local tb=new("TextBox",{Text="",PlaceholderText="kata kunci",TextSize=11,Font=Enum.Font.Gotham,TextColor3=C.txt,
		PlaceholderColor3=C.sub,BackgroundColor3=C.off,ClearTextOnFocus=false,Size=UDim2.new(0,84,0,26),
		Position=UDim2.new(1,-94,0.5,-13)},r)
	round(tb,6)
	tb.FocusLost:Connect(function()
		local t=tb.Text:lower():gsub("^%s+",""):gsub("%s+$","")
		if #t>0 then cb(t) tb.Text="" setStatus("Ditambah: "..t) end
	end)
end

----------------------------------------------------------------
-- HALAMAN
----------------------------------------------------------------
local pAuto=addTab("Auto",1)
local pTp=addTab("Teleport",2)
local pKode=addTab("Kode",3)
local pSet=addTab("Settings",4)

----------------------------------------------------------------
-- TAB TELEPORT (daftar dinamis)
----------------------------------------------------------------
local holder=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=999},pTp)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},holder)

local function buildList()
	for _,c in ipairs(holder:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	local n=0
	for _,kind in ipairs({"Key","Kertas","Pintu"}) do
		for _,o in ipairs(sortByDist(items[kind])) do
			n+=1
			local r=new("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.row,LayoutOrder=n},holder)
			round(r,8)
			label(r,"["..kind.."] "..o.Name,12,UDim2.new(0,10,0,0),UDim2.new(1,-70,1,0),C.txt,Enum.Font.GothamMedium)
			local b=new("TextButton",{Text="TP",TextSize=12,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),
				BackgroundColor3=C.acc,Size=UDim2.new(0,48,0,24),Position=UDim2.new(1,-56,0.5,-12)},r)
			round(b,6)
			b.MouseButton1Click:Connect(function()
				local p=o.Parent and posOf(o)
				if p then tpPos(p) setStatus("TP "..o.Name) else setStatus("Objek sudah hilang") end
			end)
		end
	end
	if n==0 then
		local l=label(holder,"Tidak ada objek. Tambah kata kunci di Settings.",11,UDim2.new(),UDim2.new(1,0,0,30),C.sub)
		l.TextWrapped=true
		l.LayoutOrder=1
	end
end

----------------------------------------------------------------
-- TAB KODE
----------------------------------------------------------------
local lastCodes=""
local codeBox=new("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.row,
	TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextSize=12,
	Font=Enum.Font.Gotham,TextColor3=C.txt,Text="Belum ada data. Tekan 'Cari Kertas' di tab Auto.",LayoutOrder=900},pKode)
round(codeBox,8)
new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},codeBox)

local function paperLines(o,out,seen)
	local function add(t)
		t=(tostring(t):gsub("%s+"," "))
		if #t>0 and #t<120 and not seen[t] then seen[t]=true out[#out+1]="• "..o.Name..": "..t end
	end
	local all={o}
	for _,d in ipairs(o:GetDescendants()) do all[#all+1]=d end
	for _,d in ipairs(all) do
		if (d:IsA("TextLabel") or d:IsA("TextBox") or d:IsA("TextButton")) and d.Text~="" then
			add(d.Text)
		elseif d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") then
			add(d.Name.."="..tostring(d.Value))
		end
		for k,v in pairs(d:GetAttributes()) do add(k.."="..tostring(v)) end
	end
end

local function buildCodes()
	local out,seen={}, {}
	for _,o in ipairs(items.Kertas) do
		if o.Parent then paperLines(o,out,seen) end
	end
	-- teks di layar (UI game) yang mengandung kode
	for _,o in ipairs(pg:GetDescendants()) do
		if o:IsA("TextLabel") and o.Visible and o.Text~="" and not o:IsDescendantOf(gui) then
			local t=o.Text
			local tl=t:lower()
			if tl:find("kode",1,true) or tl:find("code",1,true) or t:match("^%s*%d%d%d+%s*$") then
				t=(t:gsub("%s+"," "))
				if #t<120 and not seen[t] then seen[t]=true out[#out+1]="• Layar: "..t end
			end
		end
	end
	while #out>25 do table.remove(out) end
	if #out==0 then
		lastCodes=""
		codeBox.Text="Tidak ada teks kode ditemukan. Coba ambil kertasnya dulu, lalu tekan Cari Kertas lagi."
	else
		lastCodes=table.concat(out,"\n")
		codeBox.Text=lastCodes
	end
end

button(pKode,"Salin Hasil","Salin semua teks ke clipboard","SALIN",function()
	if lastCodes~="" and setclipboard then
		setclipboard(lastCodes)
		setStatus("Tersalin")
	else
		setStatus("Tidak ada / tidak didukung")
	end
end)

----------------------------------------------------------------
-- TAB AUTO
----------------------------------------------------------------
local busy=false
local setAutoUI

local function runAuto()
	if busy then S.auto=false if setAutoUI then setAutoUI(false,true) end return end
	busy=true
	local r=hrp()
	local origin=r and r.CFrame
	setStatus("Scan objek...")
	scan()
	local keys=sortByDist(items.Key)
	local doors=sortByDist(items.Pintu)

	for i,o in ipairs(keys) do
		if not (alive and S.auto) then break end
		local p=o.Parent and posOf(o)
		if p then
			setStatus("Key "..i.."/"..#keys)
			tpPos(p) task.wait(0.25)
			interact(o) task.wait(0.5)
		end
	end
	for i,o in ipairs(doors) do
		if not (alive and S.auto) then break end
		local p=o.Parent and posOf(o)
		if p then
			setStatus("Pintu "..i.."/"..#doors)
			tpPos(p) task.wait(0.25)
			interact(o) task.wait(0.5)
		end
	end

	if S.back and origin and alive then
		local r2=hrp()
		if r2 then r2.CFrame=origin end
	end
	if #keys==0 and #doors==0 then
		setStatus("Key/Pintu tidak ketemu")
	elseif alive then
		setStatus("Auto selesai")
	end
	S.auto=false
	if setAutoUI then setAutoUI(false,true) end
	busy=false
	if alive then buildList() end
end

local function runPapers()
	if busy then return end
	busy=true
	local r=hrp()
	local origin=r and r.CFrame
	setStatus("Scan kertas...")
	scan()
	local papers=sortByDist(items.Kertas)
	for i,o in ipairs(papers) do
		if not alive then break end
		local p=o.Parent and posOf(o)
		if p then
			setStatus("Kertas "..i.."/"..#papers)
			tpPos(p) task.wait(0.25)
			interact(o) task.wait(0.7)
		end
	end
	buildCodes()
	if S.back and origin and alive then
		local r2=hrp()
		if r2 then r2.CFrame=origin end
	end
	setStatus(#papers==0 and "Kertas tidak ketemu" or "Selesai, lihat tab Kode")
	busy=false
	if alive then buildList() end
end

local function gotoNearest(kind)
	scan()
	local list=sortByDist(items[kind])
	local o=list[1]
	local p=o and posOf(o)
	if p then
		tpPos(p)
		setStatus("TP "..o.Name)
	else
		setStatus(kind.." tidak ketemu")
	end
	buildList()
end

setAutoUI=toggle(pAuto,"Auto Key + Pintu","Ambil semua key lalu buka pintu",false,function(v)
	S.auto=v
	if v then task.spawn(runAuto) else setStatus("Auto OFF") end
end)
button(pAuto,"Cari Kertas","Ambil kertas & baca kodenya","CARI",function() task.spawn(runPapers) end)
button(pAuto,"Ke Key Terdekat","Teleport ke key terdekat","TP",function() task.spawn(gotoNearest,"Key") end)
button(pAuto,"Ke Kertas Terdekat","Teleport ke kertas terdekat","TP",function() task.spawn(gotoNearest,"Kertas") end)
button(pAuto,"Ke Pintu Terdekat","Teleport ke pintu terdekat","TP",function() task.spawn(gotoNearest,"Pintu") end)
toggle(pAuto,"Kembali ke Posisi Awal","Balik setelah auto selesai",true,function(v) S.back=v end)

button(pTp,"Scan Ulang","Cari ulang key, kertas, pintu","SCAN",function()
	setStatus("Scan...")
	task.spawn(function() scan() buildList() setStatus("Scan selesai") end)
end)

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
textRow(pSet,"Kata Kunci Key","Contoh: kunci_emas",function(t) table.insert(KEYK,t) end)
textRow(pSet,"Kata Kunci Kertas","Contoh: catatan_opah",function(t) table.insert(PAPK,t) end)
textRow(pSet,"Kata Kunci Pintu","Contoh: pintu_depan",function(t) table.insert(DOORK,t) end)
button(pSet,"Tutup Script","Hapus UI dan hentikan semua","UNLOAD",function() if _G.OPAH then _G.OPAH() end end)

do
	local armedClose=false
	bClose.MouseButton1Click:Connect(function()
		if armedClose then
			if _G.OPAH then _G.OPAH() end
			return
		end
		armedClose=true
		bClose.TextColor3=Color3.fromRGB(255,90,90)
		setStatus("Tekan X lagi untuk tutup")
		task.delay(2,function()
			if alive and bClose.Parent then
				armedClose=false
				bClose.TextColor3=C.sub
				setStatus("Siap")
			end
		end)
	end)
end

_G.OPAH=function()
	alive=false
	S.auto=false
	for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	table.clear(conns)
	gui:Destroy()
	_G.OPAH=nil
end

pAuto.Visible=true
tabBtns["Auto"].BackgroundTransparency=0
tabBtns["Auto"].TextColor3=C.txt
