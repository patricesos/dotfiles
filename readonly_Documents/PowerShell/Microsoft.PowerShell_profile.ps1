oh-my-posh --init --shell pwsh --config "$env:POSH_THEMES_PATH\amro.omp.json" | Invoke-Expression

Invoke-Expression (& { (zoxide init powershell | Out-String) })

New-Alias pe pyenv

function SymLink {
	param (
		$Target, $Path
	)
	New-Item -ItemType SymbolicLink -Path $Path -Target $Target
}

