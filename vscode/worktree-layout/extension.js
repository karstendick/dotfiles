const vscode = require("vscode");

async function activate() {
	// The Welcome page would otherwise count as an open tab and stop the layout below. This lives
	// here rather than in VS Code's settings.json because dotfiles doesn't manage that file.
	const workbench = vscode.workspace.getConfiguration("workbench");
	if (workbench.inspect("startupEditor")?.globalValue === undefined) {
		await workbench.update("startupEditor", "none", vscode.ConfigurationTarget.Global);
	}

	const folders = vscode.workspace.workspaceFolders ?? [];
	if (folders.length !== 1) return;

	// A reopened window restores its own tabs; only lay out a fresh one.
	if (vscode.window.tabGroups.all.some((group) => group.tabs.length > 0)) return;

	const readme = vscode.Uri.joinPath(folders[0].uri, "README.md");
	try {
		await vscode.workspace.fs.stat(readme);
	} catch {
		return;
	}

	await vscode.commands.executeCommand("workbench.action.closeSidebar");
	await vscode.commands.executeCommand("workbench.action.closeAuxiliaryBar");
	await vscode.window.showTextDocument(readme, {
		viewColumn: vscode.ViewColumn.One,
		preview: false,
	});
	// With no column argument, Claude Code starts its own (locked) group beside the active one.
	await vscode.commands.executeCommand("claude-vscode.editor.open");
}

module.exports = { activate };
