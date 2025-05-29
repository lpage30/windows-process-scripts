Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function CreateListView {
	[CmdletBinding(DefaultParameterSetName='CreateListView')]
	param (
		[Parameter(ParameterSetName = 'CreateListView',  HelpMessage="List Width")]
		[Int]$ListWidth = 200,

        [Parameter(ParameterSetName = 'CreateListView', HelpMessage="List Height")]
		[Int]$ListHeight = 300
    )
    [System.Windows.Forms.ListView]$list = New-Object System.Windows.Forms.ListView
    $list.Size = New-Object System.Drawing.Size($ListWidth, $ListHeight)
    $list.View = "Details"
    $list.Scrollable = $true
    $list.HeaderStyle = "None"
    $list.FullRowSelect = $true
    $columnHeader = New-Object System.Windows.Forms.ColumnHeader
    $columnHeader.Width = $ListWidth
    $notUsed = $list.Columns.Add($columnHeader)
    return $list
}

function CreateTreeView {
	[CmdletBinding(DefaultParameterSetName='CreateTreeView')]
	param (
		[Parameter(ParameterSetName = 'CreateTreeView',  HelpMessage="Tree Width")]
		[Int]$TreeWidth = 200,

        [Parameter(ParameterSetName = 'CreateTreeView', HelpMessage="Tree Height")]
		[Int]$TreeHeight = 300
    )
    [System.Windows.Forms.TreeView]$tree = New-Object System.Windows.Forms.TreeView
    $tree.Size = New-Object System.Drawing.Size($TreeWidth, $TreeHeight)
    $tree.Scrollable = $true
    $tree.CheckBoxes = $true
    return $tree
}
function CreatePickListForm {
	[CmdletBinding(DefaultParameterSetName='CreatePickListForm')]
	param (
		[Parameter(ParameterSetName = 'CreatePickListForm',  Mandatory=$true, HelpMessage="PickList Title")]
		[String]$Title,

        [Parameter(ParameterSetName = 'CreatePickListForm', Mandatory=$true,  HelpMessage="Title Placed on Button1")]
		[String]$Button1Title,

        [Parameter(ParameterSetName = 'CreatePickListForm', Mandatory=$true,  HelpMessage="Title Placed on Button2")]
		[String]$Button2Title,

        [Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="Top-Left Corner X offset position")]
		[Int]$X = 200,

        [Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="Top-Left Corner Y offset position")]
		[Int]$Y = 100,

		[Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="List Width")]
		[Int]$ListWidth = 300,

        [Parameter(ParameterSetName = 'CreatePickListForm', HelpMessage="List Height")]
		[Int]$ListHeight = 400,

        [Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="List Offset from top-left corner")]
		[Int]$ListOffset = 10,

        [Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="Padding between widgets")]
		[Int]$Padding = 10,

        [Parameter(ParameterSetName = 'CreatePickListForm',  HelpMessage="Button Width")]
		[Int]$ButtonWidth = 75,

        [Parameter(ParameterSetName = 'CreatePickListForm', HelpMessage="Button Height")]
		[Int]$ButtonHeight = 23		
	)

    [Int]$overallWidth = $ListOffset*2 + $ListWidth + [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth
    [Int]$overallHeight = [System.Windows.Forms.SystemInformation]::CaptionHeight + $ListOffset + $ButtonHeight + $Padding + $ListHeight + $Padding + $ButtonHeight + $ListOffset + $Padding

    [Int]$button1X = [Math]::Round(($ListWidth - ($ButtonWidth*2) - $Padding) / 2)
    [Int]$button2X = $button1X + $ButtonWidth + $Padding
    [Int]$buttonY = $ListOffset + $ButtonHeight + $Padding + $ListHeight + $Padding

    $form = New-Object System.Windows.Forms.Form
    $toggleViewButton = New-Object System.Windows.Forms.Button
    $button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button

    $form.Text = $Title
    $form.Location = New-Object System.Drawing.Point($X, $Y)
    $form.Size = New-Object System.Drawing.Size($overallWidth, $overallHeight)

    $toggleViewButton.Location = New-Object System.Drawing.Point([int]($overallWidth - $ListOffset - $ButtonWidth - $ListOffset), $ListOffset)
    $toggleViewButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $toggleViewButton.Text = "Toggle View"
    $notUsed = $form.Controls.Add($toggleViewButton)

    $button1.Location = New-Object System.Drawing.Point($button1X, $buttonY)
    $button1.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $button1.Text = $Button1Title
    $notUsed = $form.Controls.Add($button1)

    $button2.Location = New-Object System.Drawing.Point($button2X, $buttonY)
    $button2.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
    $button2.Text = $Button2Title
    $notUsed = $form.Controls.Add($button2)

    $tree = CreateTreeView -TreeWidth $ListWidth -TreeHeight $ListHeight
    $tree.Location = New-Object System.Drawing.Point($ListOffset, [int]($ListOffset + $ButtonHeight + $Padding))

    $list = CreateListView -ListWidth $ListWidth -ListHeight $ListHeight
    $list.Location = New-Object System.Drawing.Point($ListOffset, [Int]($ListOffset + $ButtonHeight + $Padding))

    # $notUsed =  $form.Controls.Add($tree)
    $notUsed = $form.Controls.Add($list)

    $widgets = [PSCustomObject]@{
        form = $form;
        list = $list;
        tree = $tree;
        button1 = $button1;
        button2 = $button2;
        toggleViewButton = $toggleViewButton;
    }
    $toggleView = {
        if ($widgets.form.Controls.Contains($widgets.list)) {
            $Widgets.form.Controls.Remove($widgets.list)
            $Widgets.form.Controls.Add($widgets.tree)
        } else {
            $Widgets.form.Controls.Remove($widgets.tree)
            $Widgets.form.Controls.Add($widgets.list)
        }
        $widgets.form.Refresh()
    }
    $toggleViewButton.Add_Click($toggleView)

    return $widgets
}
function ShowPickListForm {
	[CmdletBinding(DefaultParameterSetName='ShowPickListForm')]
	param (
		[Parameter(ParameterSetName = 'ShowPickListForm',  Mandatory=$true, HelpMessage="The Form to show")]
		[System.Windows.Forms.Form]$PickListForm
	)

    $notUsed = $PickListForm.Add_shown({$PickListForm.Activate()})
    return $PickListForm.ShowDialog()
}

function RefreshListView {
	[CmdletBinding(DefaultParameterSetName='RefreshListView')]
	param (
		[Parameter(ParameterSetName = 'RefreshListView',  Mandatory=$true, HelpMessage="List to refresh")]
		[System.Windows.Forms.ListView]$List,
		[Parameter(ParameterSetName = 'RefreshListView',  Mandatory=$true, HelpMessage="Array of Name=<name> Value=<value> used to populate list")]
        [PSCustomObject[]] $NameValueItemArray
	)
    $List.BeginUpdate()
    $List.Items.Clear()
    ForEach ($NameValueItem in ($NameValueItemArray | Sort-Object -Property Name)) {
        [System.Windows.Forms.ListViewItem]$item = New-Object System.Windows.Forms.ListViewItem($NameValueItem.Name)
        $item.Tag = $NameValueItem.Value
        $notUsed = $List.Items.Add($item)
    }
    $List.EndUpdate()
    $List.Refresh()
}
function RefreshTreeView {
	[CmdletBinding(DefaultParameterSetName='RefreshTreeView')]
	param (
		[Parameter(ParameterSetName = 'RefreshTreeView',  Mandatory=$true, HelpMessage="Tree to refresh")]
		[System.Windows.Forms.TreeView]$Tree,
		[Parameter(ParameterSetName = 'RefreshTreeView',  Mandatory=$true, HelpMessage="Array of Name=<name> Value=<value> used to populate tree")]
        [PSCustomObject[]] $NameValueItemArray
	)
    $Tree.BeginUpdate()
    $Tree.Nodes.Clear()

    ForEach ($nameValueItem in ($NameValueItemArray | Sort-Object -Property Name)) {
        [System.Windows.Forms.TreeNode]$item = New-Object System.Windows.Forms.TreeNode($nameValueItem.Name)
        $item.Tag = $nameValueItem.Value
        [PSCustomObject[]]$children = $nameValueItem.Value.Children
        ForEach($childNameValueItem in ($children | Sort-Object -Property Name)) {
            $subItem = New-Object System.Windows.Forms.TreeNode($childNameValueItem.Name)
            $subItem.Tag = [PSCustomObject]@{ PID=$childNameValueItem.PID; Children=@(); }
            $notUsed = $item.Nodes.Add($subItem)
        }
        $notUsed = $Tree.Nodes.Add($item)
    }
    $Tree.EndUpdate()
    $Tree.Refresh()
}

function GetSelectedListViewNameValueItems {
    [CmdletBinding(DefaultParameterSetName='GetSelectedListViewNameValueItems')]
	param (
		[Parameter(ParameterSetName = 'GetSelectedListViewNameValueItems',  Mandatory=$true, HelpMessage="List to obtain selection.")]
		[System.Windows.Forms.ListView]$List
    )
    IF ($List.SelectedItems.Count -eq 0) {
        return @()
    }
    [PSCustomObject[]] $NameValueItemArray = $List.SelectedItems | Select-Object @{Name="Name";Expression={$_.Text}}, @{Name="Value";Expression={$_.Tag}}
    return $NameValueItemArray
}
function GetSelectedTreeViewNameValueItems {
    [CmdletBinding(DefaultParameterSetName='GetSelectedTreeViewNameValueItems')]
	param (
		[Parameter(ParameterSetName = 'GetSelectedTreeViewNameValueItems',  Mandatory=$true, HelpMessage="Tree to obtain selection.")]
		[System.Windows.Forms.TreeView]$Tree
    )
    $NameValueItemArray = New-Object System.Collections.ArrayList
    ForEach ($node in $Tree.Nodes) {
        if ($node.checked) {
            $item=[PSCustomObject]@{
                Name=$node.Text;
                Value=$node.Tag;
            }
            $notUsed = $NameValueItemArray.Add($item)
            continue
        }
        ForEach ($subNode in $node.Nodes) {
            if ($subNode.checked) {
                $item=[PSCustomObject]@{
                    Name=$subNode.Text;
                    Value=$subNode.Tag;
                }
                $notUsed = $NameValueItemArray.Add($item)
            }
        }
    }
    return [PSCustomObject[]]$NameValueItemArray
}

function ForceQuitProcesses {
    param (
		[Int[]]$PIDArray
	)
    $PIDArray.ForEach({
        Stop-Process -Id $_ -Force
    })
}
function GetProcesses {
    [PSCustomObject[]]$result = get-process `
    | where-object -property MainWindowTitle `
    | Select-Object CPU, @{Name="owner";Expression={get-ciminstance Win32_process -Filter ("ProcessId={0}" -f $_.Id) | Select-Object  -ExpandProperty @{Name="owner";Expression={(invoke-cimmethod -InputObject $_ -MethodName GetOwner).User}}}} `
    | Select-Object cimprocess, `
        @{Name="owner";Expression={(invoke-cimmethod -InputObject $_.cimprocess -MethodName GetOwner).User}}, `
        @{Name="children";Expression={ 
            [PSCustomObject[]]$result = get-ciminstance Win32_process -Filter ("ParentProcessId={0}" -f $_.cimprocess.ProcessId) `
            | Select-Object Name, @{Name="PID";Expression={$_.ProcessId}}
            IF ($null -ne $result -and 0 -lt $result.Count) {
                return $result
            }
            return [PSCustomObject[]]@()
        }} `
    | Sort-Object -Property cimprocess.Name `
    | Select-Object @{Name="Name";Expression={
            [String]$result = "{0,5}  {1}" -f $_.cimprocess.ProcessId, $_.cimprocess.Name
            IF (0 -lt $_.children.Count) {
               $result = "{0}  {1,3}-({2})" -f $result, $_.children.Count, $_.children[0].Name
            }
            return $result
        }}, `
        @{Name="Value";Expression={ [PSCustomObject]@{ PID = $_.cimprocess.ProcessId; Children = [PSCustomObject[]]$_.children; }}}

    return $result
}

function RenderForceQuitDialog {
 
    $widgets = CreatePickListForm -Title "Force Quit Applications" -Button1Title "Refresh" -Button2Title "Force Quit"

    $onRefresh = {
        [PSCustomObject[]]$processNameValueItemArray = GetProcesses
        if($null -ne $widgets.list) {
            RefreshListView -List $widgets.list -NameValueItemArray $processNameValueItemArray
        }
        if ($null -ne $widgets.tree) {
            RefreshTreeView -Tree $widgets.tree -NameValueItemArray $processNameValueItemArray
        }
    }

    $onForceQuit = {
        [PSCustomObject[]]$items = @()
        if ($null -ne $widgets.list -and $widgets.form.Controls.Contains($widgets.list)) {
            $items = GetSelectedListViewNameValueItems -List $widgets.list
        }
        if ($null -ne $widgets.tree-and $widgets.form.Controls.Contains($widgets.tree)) {
            $items = GetSelectedTreeViewNameValueItems -Tree $widgets.tree
        }
        $items.ForEach({
            Write-Host ("{0} {1} {2} {3}" -f $_.Name, $_.Value, $_.Value.PID, $_.Value.Children[0].Name)
        })
        

        [Int[]]$pidArray = $items | Select-Object -ExpandProperty  Value | Select-Object -ExpandProperty PID
        ForceQuitProcesses -PIDArray $pidArray
        $onRefresh

    }
    $widgets.button1.Add_Click($onRefresh)
    $widgets.button2.Add_Click($onForceQuit)

    &$onRefresh

    ShowPickListForm -PickListForm $widgets.form
}

RenderForceQuitDialog