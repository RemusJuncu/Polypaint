(
	global PolyPaintUI
	try destroyDialog PolyPaintUI catch ()

	rollout PolyPaintUI "Polypaint 0.2" height:93 (
		local isInstalled = ( not matchPattern (getSourceFileName()) pattern:((pathConfig.getdir #userScripts)+"*") )
		fn setupmenu = (
			rcMenu addremove (
				-- fn fromBox = ( not matchPattern (getSourceFileName()) pattern:((pathConfig.getdir #userScripts)+"*") )
				menuitem btn1_mi "Install" enabled:PolyPaintUI.isInstalled
				menuitem btn2_mi "Uninstall" enabled:( not PolyPaintUI.isInstalled )
				
				on btn1_mi picked do PolyPaintUI.install()
				on btn2_mi picked do PolyPaintUI.uninstall()
			)
			popUpMenu addremove align:#align_topcenter
		)

		fn install = try (
			if queryBox "Install and add macroscript !?" do (
				local userScriptFile = pathConfig.appendPath (pathConfig.getdir #userScripts) (filenameFromPath (getSourceFileName()))
				if doesfileexist userScriptFile do deleteFile userScriptFile
				copyFile (getSourceFileName()) userScriptFile
				local theMacro = (
"macroScript polypaint category:\"RappaTools3\" buttontext:\"Polypaint\" --silentErrors:TRUE
tooltip:\"Polypaint 0.2\"
(
	on execute do (
		local polypaintfile = pathConfig.appendPath (pathConfig.getdir #userScripts) \"" + (filenameFromPath (getSourceFileName())) + "\"
		if doesfileexist polypaintfile do filein polypaintfile
	)
)"
				)
				local mcrpath = pathConfig.appendPath (pathConfig.getDir #userScripts) "RappaTools3-polypaint.mcr"
				(dotnetclass "System.IO.File").WriteAllText mcrpath theMacro
				filein mcrpath
				local gozmenu = menuMan.findMenu "GoZ"
				if gozmenu != undefined then (
					gozmenu.addItem (menuMan.createActionItem "polypaint" "RappaTools3") 0
					menuMan.updateMenuBar()
					messagebox "You can now find Polypaint under GoZ menu.\nAlso can be found under RappaTools3 category."
				) else ( messagebox "You can now find Polypaint under RappaTools3 category." )
				filein userScriptFile
			)
		) Catch ( messagebox "Something went wrong..." )
		fn uninstall = try (
			local userScriptFile = pathConfig.appendPath (pathConfig.getdir #userScripts) (filenameFromPath (getSourceFileName()))
			if doesfileexist userScriptFile do deleteFile userScriptFile
			local mcrpath = pathConfig.appendPath (pathConfig.getDir #userMacros) "RappaTools3-polypaint.mcr"
			if doesfileexist mcrpath do deleteFile mcrpath
			local gozmenu = menuMan.findMenu "GoZ"
			if gozmenu != undefined do (
				for i = 1 to gozmenu.numItems() do (
					if (gozmenu.getItem i).getTitle() == "Polypaint" do (
						gozmenu.removeItem (gozmenu.getItem i)
					)
				)
				menuMan.updateMenuBar()
			)
			try destroyDialog PolyPaintUI catch ()
			messagebox "Polypaint has been removed."
		) catch ( messagebox "Something went wrong..." )
		fn getPolyPaint file: = if selection.count == 1 then (
			if file == unsupplied do file = getOpenFileName caption:"Get polypaint from file:" types:"Wavefront OBJ|*.obj"
			if file != undefined and doesfileexist file do with redraw off (
				setWaitCursor()
				local localTimeStamp = timestamp()
				local data = (dotnetclass "System.IO.File").ReadAllLines file -- print data
				local vCountEmpty = true, fileVCount = 0
				for v in data while vCountEmpty do (
					if findString v "#Vertex Count " != undefined do (
						fileVCount = (substring v 15 v.count) as integer
						vCountEmpty = false
					)
				)
				if not vCountEmpty and selection[1].numverts == fileVCount then (
					if classof selection[1] == Editable_mesh then (
						local mrgbarray = (for x in data where (findString x "#MRGB ") != undefined collect substring x 7 x.count)
						if mrgbarray.count == 0 then messagebox "No Polypaint in the file !?" else (
							local selbas = selection[1], mv = 1

							disableRefMsgs()
							windows.sendmessage (windows.getmaxhwnd()) 0x000B 0 1

							defaultVCFaces selection[1]
							for hexstring in mrgbarray do (
								local hexstringcount = hexstring.count
								for b = 1 to hexstringcount by 8 do (
									local rgbclr = color (("0x" + hexstring[b+2] + hexstring[b+3]) as integer) (("0x" + hexstring[b+4] + hexstring[b+5]) as integer) (("0x" + hexstring[b+6] + hexstring[b+7]) as integer) -- ("0x" + substring hexclr 1 2) as integer
									setvertcolor selbas mv rgbclr
									mv += 1
								)
							)

							enableRefMsgs()
							windows.sendmessage (windows.getmaxhwnd()) 0x000B 1 1

							selection[1].showVertexColors = on
							selection[1].vertexColorsShaded = on
							update selection[1]
							redrawviews()

							format "polypaint: %s | http://remusjuncu.com/\n" ((timestamp()-localTimeStamp)/1000.0)
						)
					) else ( messagebox "Object has to be Editable Mesh !!!" )
				) else messagebox "Not the same object !?\n\nVertex count does not match."
				setArrowCursor()
			)
		) else ( messageBox "Select the object inside the obj in order to assign the polypaint" )

		button importbtn "Import with Polypaint" align:#center width:130 toolTip:"Import object with polypaint from obj file.\n\nRightClick for Add Remove menu."
		button getpolypaintbtn "Get Polypaint" align:#center width:130 offset:[0,-3] toolTip:"Get polypaint from obj file.\n\nRightClick for Add Remove menu."
		button weblink "http://remusjuncu.com/" align:#center width:130 height:16 toolTip:"Made by Remus Juncu"
		button weblink2 "RappaTools3 Pro Toolbox" align:#center width:130 height:16 offset:[0,-3] toolTip:"3ds Max Maxscript"

		on weblink pressed do shellLaunch "http://remusjuncu.com/" ""
		on weblink2 pressed do shellLaunch "http://remusjuncu.com/rappatools/" ""
		on importbtn pressed do (
			local objfile = getOpenFileName caption:"Object file:" types:"Wavefront OBJ|*.obj"
			if objfile != undefined and doesfileexist objfile do (
				local userTaskMode = getCommandPanelTaskMode()
				if userTaskMode != #create do setCommandPanelTaskMode mode:#create
				local importIni = objimp.getIniName()
				local userSingleMesh = getIniSetting importIni "Objects" "SingleMesh"
				local userEditPoly = getIniSetting importIni "Objects" "AsEditablePoly"
				setIniSetting importIni "Objects" "SingleMesh" "1"
				setIniSetting importIni "Objects" "AsEditablePoly" "0"
				importFile objfile #noPrompt
				setIniSetting importIni "Objects" "SingleMesh" userSingleMesh 
				setIniSetting importIni "Objects" "AsEditablePoly" userEditPoly 
				getPolyPaint file:objfile
				setCommandPanelTaskMode mode:userTaskMode
			)
		)
		on getpolypaintbtn pressed do getPolyPaint ()

		on importbtn rightclick do setupmenu()
		on getpolypaintbtn rightclick do setupmenu()
		on weblink rightclick do setupmenu()
		on weblink2 rightclick do setupmenu()
	)

	CreateDialog PolyPaintUI style:#(#style_SysMenu, #style_ToolWindow)
)
