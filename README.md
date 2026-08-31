# blockster

A new Flutter project.

Create a Flutter project that creates a 10*10 grid in the middle of the screen.

## The blocks
There is a set of 5 blocks made in a grid format.
1 is red and is a 3x3 square.
2 is blue and has 2*1 horizontal retangle with a 1*1 square on top of the right square to make a block.
3 is green and has 3*1 horizontal rectangle with a 2*1 vertical rectangle on top of the left square to make a block.
4 is purple and has 3*1 vertical rectangle with a 1*1 square on each side of the square in the middle.
5 is pink and has a 3*1 vertical rectangle with a 1*1 square on the right side of the square on top.


## The gameplay
When they start the Game they get 3 random blocks from the set of 5 possible blocks.
Each round they also get 3 random blocks from the set of 5 possible blocks
Each round they must drag the blocks in the grid, and the blocks snap into place if there is no blocks in that spot.
When they use all the blocks a new round starts.
Whenever they create a row or column with the blocks, the blocks in that row disappear, and they get 10 points.
If they create a row and column at the same time with thier blocks they should get 2 times the amount of points for the next 10 moves.
When they get points star shaped confetti should shoot out from the bottom of the screen.
Show thier points at the top of the Grid.
Make a button that has exit on it that takes them to the menu

## Menu
When you run the project it starts at a game start menu with the title blockster in the top middle of the screen.
Then add a green button with word Start game visible on the button.
Add a gradient background that is the color red and blue and loops around the background forever.

## The lose screen
While playing the game if they can't add a block anywhere send them to a lose screen.
On the lose screen thier is an input box that allows up to 3 letters.
Using shared_preference add thier input into a leaderboard that is aranged from highest to lowest.
