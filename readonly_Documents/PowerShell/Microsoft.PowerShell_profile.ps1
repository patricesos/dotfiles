
Invoke-Expression (& { (zoxide init powershell | Out-String) })

New-Alias pe pyenv

function SymLink {
	param (
		$Target, $Path
	)
	New-Item -ItemType SymbolicLink -Path $Path -Target $Target
}

#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression
