const toggleButton = document.getElementById('dark-mode-toggle');
const body = document.body;
const localStorageKey = 'darkModeEnabled';

function applyTheme(isDark)
{
	if (isDark)
	{
		body.classList.add('dark-mode');
		toggleButton.textContent = 'Switch to Light Mode';
		localStorage.setItem(localStorageKey, 'true');
	}
	else
	{
		body.classList.remove('dark-mode');
		toggleButton.textContent = 'Switch to Dark Mode';
		localStorage.setItem(localStorageKey, 'false');
	}
}

function loadTheme()
{
	const savedTheme = localStorage.getItem(localStorageKey);

	if (savedTheme !== null)
	{
		applyTheme(savedTheme === 'true');
	}
	else
	{
		const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
		applyTheme(prefersDark);
	}
}
loadTheme();

toggleButton.addEventListener('click', function()
	{
		const isCurrentlyDark = body.classList.contains('dark-mode');

		applyTheme(!isCurrentlyDark);
	}
);
