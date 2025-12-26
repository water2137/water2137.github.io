document.addEventListener('DOMContentLoaded', () => {
    const gridEl = document.getElementById('game-board');
    const mineCounterEl = document.getElementById('mine-counter');
    const timerEl = document.getElementById('timer');
    const smileyBtn = document.getElementById('smiley-btn');

    // Game Settings (Intermediate default-ish)
    const ROWS = 9;
    const COLS = 9;
    const MINES = 10;

    let grid = []; // Internal state: { isMine, isRevealed, isFlagged, neighborCount }
    let gameActive = false;
    let firstClick = true;
    let flagsPlaced = 0;
    let timeElapsed = 0;
    let timerInterval = null;

    // Initialize Game
    function initGame() {
        // Reset State
        grid = [];
        gameActive = true;
        firstClick = true;
        flagsPlaced = 0;
        timeElapsed = 0;
        stopTimer();
        
        // Reset UI
        mineCounterEl.textContent = formatNumber(MINES);
        timerEl.textContent = "000";
        smileyBtn.className = 'smiley-btn'; // Normal face
        gridEl.innerHTML = '';
        gridEl.style.gridTemplateColumns = `repeat(${COLS}, 16px)`;
        gridEl.style.gridTemplateRows = `repeat(${ROWS}, 16px)`;

        // Create Grid UI & State
        for (let r = 0; r < ROWS; r++) {
            const rowData = [];
            for (let c = 0; c < COLS; c++) {
                // State
                rowData.push({
                    r, c,
                    isMine: false,
                    isRevealed: false,
                    isFlagged: false,
                    neighborCount: 0
                });

                // UI
                const cell = document.createElement('div');
                cell.classList.add('cell');
                cell.dataset.r = r;
                cell.dataset.c = c;
                
                // Event Listeners
                cell.addEventListener('mousedown', (e) => handleMouseDown(e, r, c));
                cell.addEventListener('mouseup', (e) => handleMouseUp(e, r, c));
                cell.addEventListener('mouseleave', () => smileyBtn.classList.remove('oh'));
                cell.addEventListener('contextmenu', (e) => {
                    e.preventDefault(); // Block context menu
                    toggleFlag(r, c);
                });

                gridEl.appendChild(cell);
            }
            grid.push(rowData);
        }
    }

    // Handle Mouse Down (Face interaction)
    function handleMouseDown(e, r, c) {
        if (!gameActive || grid[r][c].isRevealed || grid[r][c].isFlagged) return;
        if (e.button === 0) { // Left click
            smileyBtn.classList.add('oh');
            const cell = getCellEl(r, c);
            cell.classList.add('active-press');
        }
    }

    // Handle Mouse Up
    function handleMouseUp(e, r, c) {
        if (!gameActive) return;
        smileyBtn.classList.remove('oh');
        const cell = getCellEl(r, c);
        cell.classList.remove('active-press');

        if (e.button === 0) { // Left Click
            handleClick(r, c);
        }
    }

    function handleClick(r, c) {
        const cellState = grid[r][c];
        
        if (cellState.isFlagged || cellState.isRevealed) return;

        if (firstClick) {
            startTimer();
            // LOOOOOOOOOL
            spawnMines(r, c); 
            firstClick = false;
        }

        if (cellState.isMine) {
            gameOver(r, c);
        } else {
            revealCell(r, c);
            checkWin();
        }
    }

    function spawnMines(firstR, firstC) {
        // Place mine at first click
        grid[firstR][firstC].isMine = true;

        let minesPlaced = 1;

        // Place remaining mines randomly
        while (minesPlaced < MINES) {
            const r = Math.floor(Math.random() * ROWS);
            const c = Math.floor(Math.random() * COLS);

            if (!grid[r][c].isMine) {
                grid[r][c].isMine = true;
                minesPlaced++;
            }
        }

        // Calculate numbers
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                if (!grid[r][c].isMine) {
                    grid[r][c].neighborCount = countNeighbors(r, c);
                }
            }
        }
    }

    function countNeighbors(r, c) {
        let count = 0;
        for (let i = -1; i <= 1; i++) {
            for (let j = -1; j <= 1; j++) {
                const nr = r + i;
                const nc = c + j;
                if (nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS) {
                    if (grid[nr][nc].isMine) count++;
                }
            }
        }
        return count;
    }

    function revealCell(r, c) {
        const cellState = grid[r][c];
        if (cellState.isRevealed || cellState.isFlagged) return;

        cellState.isRevealed = true;
        const cellEl = getCellEl(r, c);
        cellEl.classList.add('revealed');

        if (cellState.neighborCount > 0) {
            cellEl.textContent = cellState.neighborCount;
            cellEl.classList.add(`n${cellState.neighborCount}`);
        } else {
            // Flood fill
            for (let i = -1; i <= 1; i++) {
                for (let j = -1; j <= 1; j++) {
                    const nr = r + i;
                    const nc = c + j;
                    if (nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS) {
                        if (!grid[nr][nc].isMine && !grid[nr][nc].isRevealed) {
                            revealCell(nr, nc);
                        }
                    }
                }
            }
        }
    }

    function toggleFlag(r, c) {
        if (!gameActive || grid[r][c].isRevealed) return;
        
        const cellState = grid[r][c];
        const cellEl = getCellEl(r, c);

        if (cellState.isFlagged) {
            cellState.isFlagged = false;
            cellEl.classList.remove('flag');
            flagsPlaced--;
        } else {
            if (flagsPlaced < MINES) {
                cellState.isFlagged = true;
                cellEl.classList.add('flag');
                flagsPlaced++;
            }
        }
        mineCounterEl.textContent = formatNumber(MINES - flagsPlaced);
    }

    function gameOver(hitR, hitC) {
        gameActive = false;
        stopTimer();
        smileyBtn.classList.add('dead');
        
        // Reveal all mines
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                const cellState = grid[r][c];
                const cellEl = getCellEl(r, c);

                if (cellState.isMine) {
                    cellEl.classList.add('mine');
                    if (r === hitR && c === hitC) {
                        cellEl.classList.add('exploded');
                    }
                } else if (cellState.isFlagged) {
                    cellEl.classList.add('misflagged');
                }
            }
        }
    }

    function checkWin() {
        let revealedCount = 0;
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                if (grid[r][c].isRevealed) revealedCount++;
            }
        }

        if (revealedCount === (ROWS * COLS) - MINES) {
            gameActive = false;
            stopTimer();
            smileyBtn.classList.add('cool');
            flagAllMines();
        }
    }

    function flagAllMines() {
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                if (grid[r][c].isMine && !grid[r][c].isFlagged) {
                    grid[r][c].isFlagged = true;
                    getCellEl(r, c).classList.add('flag');
                }
            }
        }
        mineCounterEl.textContent = "000";
    }

    function getCellEl(r, c) {
        return gridEl.children[r * COLS + c];
    }

    function formatNumber(num) {
        if (num < -99) return "-99";
        if (num > 999) return "999";
        if (num < 0) return `-${Math.abs(num).toString().padStart(2, '0')}`;
        return num.toString().padStart(3, '0');
    }

    function startTimer() {
        stopTimer();
        timerInterval = setInterval(() => {
            timeElapsed++;
            if (timeElapsed > 999) timeElapsed = 999;
            timerEl.textContent = formatNumber(timeElapsed);
        }, 1000);
    }

    function stopTimer() {
        if (timerInterval) clearInterval(timerInterval);
    }

    // Smiley Reset
    smileyBtn.addEventListener('click', initGame);

    // Initial Start
    initGame();

    // Taskbar Clock
    function updateClock() {
        const now = new Date();
        const hours = now.getHours();
        const minutes = now.getMinutes();
        const ampm = hours >= 12 ? 'PM' : 'AM';
        const displayHours = hours % 12 || 12;
        const displayMinutes = minutes < 10 ? '0' + minutes : minutes;
        
        document.getElementById('taskbar-clock').textContent = `${displayHours}:${displayMinutes} ${ampm}`;
    }

    setInterval(updateClock, 1000);
    updateClock();
});
