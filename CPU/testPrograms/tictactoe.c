void main() {
    player = 1;
    rnd = 3;
    gui();
}

struct game {
    short cell[9];
    short count;
    short lastMove;
} // sizeof(struct game) == 11

bool testWin(struct game *game, short player) {
    if (game->lastMove < 0) return false;
    if (game->lastMove < 3) {
        if (game->cell[0] == player && 
            game->cell[1] == player &&
            game->cell[2] == player)
            return true;
    }
    else if (game->lastMove < 6) {
        if (game->cell[3] == player && 
            game->cell[4] == player &&
            game->cell[5] == player)
            return true;
    } 
    else {
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
    else if (game->lastMove == 1 || game->lastMove == 4 || game->lastMove == 7) {
        if (game->cell[1] == player && 
            game->cell[4] == player &&
            game->cell[7] == player)
            return true;
    }
    else {
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

short choise;

short minimax(struct game *game, short player) {
    short score = scoreGame(game);
    if (score != 0 || game->count == 9) return score;

    short bestMove = -1;
    if (player == 1) score = -11;
    else score = 11;

    short prevMove = game->lastMove;

    game->count++;
    for (int move = 0; move < 9; move++) {
        if (game->cell[move] != 0) continue;
        game->cell[move] = player;
        game->lastMove = move;
        short newScore = minimax(game, player ^ 0x3);
        if (player == 1) {
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
        game->cell[move] = 0;
    }
    game->count--;
    choise = bestMove;
    game->lastMove = prevMove;
    return score;
}

char boardLine[6] = "|   |";
char turn[5] = "turn";
char your[5] = "Your";
char rcpu[5] = "RCPU";
char youWon[11]  = "You won!  ";
char youLost[11] = "You lost! ";
char tie[11]     = "It's a tie";

bool gameOver;
short player;
short rnd;

struct game game;

void irint(short key) {
    if (key == 0) {
        player ^= 3;
        gui();
        return;
    }
    if (gameOver) {
        gui();
        return;
    }
    short cell = key-1;
    if (game->cell[cell] == 0) {
        game->lastMove = cell;
        game->count++;
        game->cell[cell] = player;
        if (cell < 3)
            lcd_setrowcol(0, 8+cell);
        else if (cell < 6)
            lcd_setrowcol(1, 5+cell);
        else
            lcd_setrowcol(2, 2+cell);

        if (player == 1)
            lcd_putc('X');
        else
            lcd_putc('O');

        lcd_setrowcol(3, 5);

        if (player == 1) {
            if (scoreGame(&game) > 0) {
                lcd_prints(youWon);
                gameOver = true;
                return;
            }
            else
                lcd_prints(rcpu);
        } else {
            if (scoreGame(&game) < 0) {
                lcd_prints(youWon);
                gameOver = true;
                return;
            }
            else
                lcd_prints(rcpu);
        }

        if (game->count == 9) {
            lcd_setrowcol(3, 5);
            lcd_prints(tie);
            gameOver = true;
            return;
        }
        

        solve(&game, player ^ 0x3);

        game->lastMove = choise;
        game->count++;
        game->cell[choise] = player ^ 0x3;
        if (choise < 3)
            lcd_setrowcol(0, 8+choise);
        else if (choise < 6)
            lcd_setrowcol(1, 5+choise);
        else
            lcd_setrowcol(2, 2+choise);

        if (player == 2)
            lcd_putc('X');
        else
            lcd_putc('O');

        lcd_setrowcol(3, 5);
        if (player == 2) {
            if (scoreGame(&game) > 0) {
                lcd_prints(youLost);
                gameOver = true;
                return;
            }
            else
                lcd_prints(your);
        } else {
            if (scoreGame(&game) < 0) {
                lcd_prints(youLost);
                gameOver = true;
                return;
            }
            else
                lcd_prints(your);
        }       

        if (game->count == 9) {
            lcd_setrowcol(3, 5);
            lcd_prints(tie);
            gameOver = true;
            return;
        } 
        
    }
}

void gui() {
    lcd_init();
    for (short i = 2; i > 0; i--) {
        lcd_setrowcol(i, 7);
        lcd_prints(boardLine);
    }
    lcd_setrowcol(3, 5);
    lcd_prints(your);
    lcd_setrowcol(3, 11);
    lcd_prints(turn);
    for (short i = 0; i < 9; i++) {
        game.cell[i] = 0;
    }
    game.count = 0;
    gameOver = false;
    rnd += 5;
    if (rnd > 8) rnd -= 9;
    if (player == 2) {
        game->lastMove = rnd;
        game->count++;
        game->cell[rnd] = 1;
        if (rnd < 3)
            lcd_setrowcol(0, 8+rnd);
        else if (rnd < 6)
            lcd_setrowcol(1, 5+rnd);
        else
            lcd_setrowcol(2, 2+rnd);
        lcd_putc('X');
    }
    set_irint(&irint);
}

void solve(struct game *game, short player) {
    /*if (game->count == 0)
        choise = 0;
    else */if (game->count == 1) {
        if (game->lastMove != 4)
            choise = 4;
        else 
            choise = 0;
    }
    /*else if (game->count == 2) {
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
    }*/
    else minimax(game, player);
}
