#define MAXSIZE 1024

struct game {
    short cell[9];
    short count;
    short lastMove;
} // sizeof(struct game) == 11

struct hashEntry {
    bool written;
    short cell[9];
    short score;
} // sizeof(struct hashEntry) == 11

struct hashEntry hashTable[MAXSIZE];

/* Hashing: XOR following:
    |9876543210|
    |XX        | - cell[0]
    | XX       | - cell[1]
    |  XX      | - cell[2]
    |   XX     | - cell[3]
    |    XX    | - cell[4]
    |     XX   | - cell[5]
    |      XX  | - cell[6]
    |       XX | - cell[7]
    |        XX| - cell[8]

*/

short hashGame(struct game *game) {
    short hash = 0;
    for (short i = 0; i < 9) {
        hash ^= game->cell[i];
        hash <<= 1;
    }
    return hash;
}

bool cmpGame(struct game *game1, struct hashEntry *game2) {
    for (short i = 0; i < 9) {
        if (game1->cell[i] != game2->cell[i]) return false;
    }
    return true;
}

bool testWin(struct game *game, short player) {
    if (game->lastMove < 3) {
        if (game->cell[0] == player && 
            game->cell[1] == player &&
            game->cell[2] == player)
            return true;
    }
    if (game->lastMove >= 3 && game->lastMove < 6) {
        if (game->cell[3] == player && 
            game->cell[4] == player &&
            game->cell[5] == player)
            return true;
    } 
    if (game->lastMove >= 6) {
        if (game->cell[6] == player && 
            game->cell[7] == player &&
            game->cell[8] == player)
            return true;
    } 
    if (game->lastMove == 0 || game->lastMove == 3 || game->lastMove == 6) {
        if (game->cell[0] == player && 
            game->cell[3] == player &&
            game->cell[6] == player)
            return true;
    }
    if (game->lastMove == 1 || game->lastMove == 4 || game->lastMove == 7) {
        if (game->cell[1] == player && 
            game->cell[4] == player &&
            game->cell[7] == player)
            return true;
    }
    if (game->lastMove == 2 || game->lastMove == 5 || game->lastMove == 8) {
        if (game->cell[2] == player && 
            game->cell[5] == player &&
            game->cell[8] == player)
            return true;
    }
    if ((game->lastMove & 0x3) == 0) {
        if (game->cell[0] == player && 
            game->cell[4] == player &&
            game->cell[8] == player)
            return true;
    }
    if (game->lastMove == 2 || game->lastMove == 4 || game->lastMove == 6) {
        if (game->cell[2] == player && 
            game->cell[4] == player &&
            game->cell[6] == player)
            return true;
    }
    return false;
}

short scoreGame(struct game *game) {
    if (testWin(game, 1))
        return game->count;
    if (testWin(game, 2))
        return -game->count;
    return 0;
}

short choice;

short minimax(struct game *game, short player) {
    short hash = hashGame(game);
    struct hashEntry *hashedGame = &hashTable[hash];
    for (; hashedGame->written; hashedGame++)
    {
        if (cmpGame(game, hashedGame)) {
            return hashedGame->score;
        }
        if (hashedGame == &hashTable[hash-1])
            break;
    }
    short score = scoreGame(game);
    if (score == 0 && depth != 9) {
        short bestMove = -1;
        if (player == 1) score = -11;
        else score = 11;

        game->count++;
        for (short move = 0; move < 9; move++) {
            if (game->cell[move] != 0) continue;
            game->cell[move] = player;
            game->lastMove = move;
            short newScore = minimax(game, player ^ 0x3);
            if (player == 2) {
                if (newScore > score) {
                    score = newScore;
                    bestMove = move;
                }
            } else {
                if (newScore < score) {
                    score = newScore;
                    bestMove = move;
                }
            }
        }
        game->count--;
        choise = bestMove;
        game->lastMove = prevMove;
    }

    for (hashedGame = &hashTable[hash]; 
         hashedGame->written; 
         hashedGame++) {
        hashedGame &= 0x3FFF
        if (hashedGame == &hashTable[hash-1])
            return score;
    }
    hashedGame->written = true;
    for (short i = 0; i < 9; i++)
        hashedGame->cell[i] = game->cell[i];
    hashedGame->score = score;

    return score;
}

char boardLine[6] = "|   |";
char turn[5] = "turn";
char your[5] = "Your";
char rcpu[5] = "RCPU";

short player;

struct game game;

void irint(short key) {
    if (key == 0) {
        gui();
        return;
    }
    short cell = key-1;
    if (board[cell] == 0) {
        game->lastMove = cell;
        game->count++;
        game->cell[cell] = player;
        if (cell < 3)
            lcd_setrowcol(0, 8+cell);
        else if (cell < 6)
            lcd_setrowcol(0, 5+cell);
        else
            lcd_setrowcol(0, 2+cell);

        if (player == 1)
            lcd_putc('X')
        else
            lcd_putc('O')

        lcd_setrowcol(3, 5);
        lcd_prints(rcpu);

        solve(&game, player ^ 0x3);

        game->lastMove = choise;
        game->count++;
        game->cell[choise] = player ^ 0x3;
        if (choise < 3)
            lcd_setrowcol(0, 8+cell);
        else if (choise < 6)
            lcd_setrowcol(0, 5+cell);
        else
            lcd_setrowcol(0, 2+cell);

        if (player == 2)
            lcd_putc('X')
        else
            lcd_putc('O')

        lcd_setrowcol(3, 5);
        lcd_prints(your);
    }
}

void gui() {
    lcd_init();
    for (short i = 0; i < 3; i++) {
        lcd_setrowcol(i, 7);
        lcd_prints(boardLine);
    }
    lcd_setrowcol(3, 5);
    lcd_prints(your);
    lcd_setrowcol(3, 11);
    lcd_prints(turn);
    for (short i = 0; i < 9; i++) {
        game[i] = 0;
    }
    player = 1;
    set_irint(&irint);
}

void solve(struct game *game, short player) {
    if (game->count == 0)
        choise = 0;
    else if (game->count == 1) {
        if (game->lastMove != 4)
            choise = 4;
        else 
            choise = 0;
    }
    else if (game->count == 2) {
        if (game->lastMove < 3)
            choise = 3;
        else if (game->lastMove < 5)
            choise = 1;
        else if (game->lastMove == 5)
            choise = 4;
        else if (game->lastMove == 6)
            choise = 1;
        else
            choise = 2;
    }
    else minimax(game, player);
}
