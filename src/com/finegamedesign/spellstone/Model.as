package com.finegamedesign.spellstone
{
    public class Model
    {
        internal static const EMPTY:String = " ";
        internal static const LETTER_MAX:int = 8;
        internal static const LETTER_MIN:int = 3;
        internal static var levels:Array = [
            {columnCount: 5, rowCount: 1, diagram: "LOVED"},
            {columnCount: 3, rowCount: 2, grade: 1},
            {columnCount: 3, rowCount: 3, grade: 2},
            {columnCount: 4, rowCount: 3, grade: 3},
            {columnCount: 5, rowCount: 3, grade: 4},
            {columnCount: 6, rowCount: 3, grade: 5},
            {columnCount: 6, rowCount: 4, grade: 6},
            {columnCount: 6, rowCount: 4, grade: 7},
            {columnCount: 6, rowCount: 4, grade: 8},
            {columnCount: 6, rowCount: 4, grade: 9}
        ];

        internal var diagram:String;
        internal var kill:int;
        internal var maxKill:int;
        internal var grade:int;
        internal var cellCount:int;
        internal var columnCount:int;
        internal var onContagion:Function;
        internal var onDeselect:Function;
        internal var onDie:Function;
        internal var onDieBonus:Function;
        internal var rowCount:int;
        internal var selected:Array;
        internal var table:Array;
        internal var highScore:int;
        internal var score:int;
        internal var restartScore:int;
        internal var round:int;
        internal var roundMax:int = levels.length;  
                                    // 1;  // debug
        internal var removedLabels:Array;
        internal var words:Array;
        internal var valid:Boolean;

        public function Model()
        {
            highScore = 0;
            restart();
        }

        internal function restart():void
        {
            round = 1;
            score = 0;
            restartScore = 0;
        }

        internal function populate(levelParams:Object):void
        {
            for (var param:String in levelParams) {
                this[param] = levelParams[param];
            }
            cellCount = rowCount * columnCount;
            if ("diagram" in levelParams) {
                table = levelParams.diagram.split("");
                words = [levelParams.diagram];
            }
            else {
                words = shuffleWords(Words.lists, grade,
                    cellCount, LETTER_MIN, LETTER_MAX);
                table = fillTable(words, columnCount, rowCount);
                round++;
            }
            removedLabels = populateRemovedLabels(cellCount);
            selected = [];
            kill = 0;
            restartScore = score;
            maxKill = occupied(table);
            valid = updateValid();
        }

        private function populateRemovedLabels(cellCount:int):Array
        {
            var removedLabels:Array = [];
            for (var c:int = 0; c < cellCount; c++) {
                removedLabels[c] = "none";
            }
            return removedLabels;
        }

        private static function randomLetter():String
        {
            var ALPHABET:Array = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
            var i:int = Math.random() * ALPHABET.length;
            var letter:String = ALPHABET[i];
            return letter;
        }

        /**
         * First word from grade level, then next lower grade.
         * Same word not added twice.
         * Ignore words not in all valid words list.
         * Word length from min to max.
         */
        private function shuffleWords(lists:Array, grade:int,
                cellCount:int, minLength:int, maxLength:int):Array
        {
            var words:Array = [];
            var letterCount:int = 0;
            var list:Array;
            grade++;
            while (letterCount + minLength < cellCount) {
                if (2 <= grade) {
                    grade--;
                    list = lists[grade];
                    shuffle(list);
                }
                for (var s:int = 0; letterCount + minLength < cellCount 
                                    && s < list.length; s++) {
                    maxLength = Math.max(minLength, 
                        Math.min(maxLength, cellCount - letterCount));

                    var word:String = list[s];
                    if (Words.has(word) && minLength <= word.length && word.length <= maxLength && words.indexOf(word) <= -1) {
                        // trace("Model.shuffleWords: " + word + " min " + minLength + " max " + maxLength + " grade " + grade);
                        words.push(word);
                        letterCount += word.length;
                        if (2 <= grade) {
                            grade--;
                            list = lists[grade];
                            shuffle(list);
                        }
                    }
                }
            }
            if (cellCount < letterCount) {
                throw new Error("Expected exactly one letter for each cell.  Got " + letterCount + " letters for " + cellCount + " cells.");
            }
            return words;
        }

        /**
         * Try to keep words contiguous.
         * Set possibles at corners.
         * Randomly select cell from possibles to be a cursor.
         * Select a random neighbor to spell a word.
         * If no neighbor, select from possibles.
         */ 
        private function fillTable(words:Array, columnCount:int, rowCount:int):Array
        {
            var attempts:int = 64;
            var tables:Array = [];
            for (var attempt:int = 0; attempt < attempts; attempt++) {
                var islands:int = 0;
                var table:Array = [];
                var cellCount:int = columnCount * rowCount;
                for (var c:int = 0; c < cellCount; c++) {
                    table.push(EMPTY);
                }
                for (var w:int = 0; w < words.length; w++) {
                    var cursor:int = corner(table, columnCount, rowCount);
                    for (var i:int = 0; i < words[w].length; i++) {
                        table[cursor] = words[w].substr(i, 1);
                        cursor = liberty(table, cursor, columnCount, rowCount);
                        if (-1 == cursor) {
                            cursor = corner(table, columnCount, rowCount);
                            islands++;
                        }
                    }
                }
                tables.push({islands: islands, table: table});
                if (0 == islands) {
                    break;
                }
            }
            tables.sortOn("islands", Array.NUMERIC);
            return tables[0].table;
        }

        /**
         * Random with least neighbors.  Except, avoid isolated.
         */
        private function corner(table:Array, columnCount:int, rowCount:int):int
        {
            var neighborCounts:Array = [[], [], [], [], []];
            var cellCount:int = columnCount * rowCount;
            var n:int;
            var index:int = -1;
            for (var c:int = 0; c < cellCount; c++) {
                if (table[c] == EMPTY) {
                    // return c;
                    n = adjacents(table, c, columnCount, rowCount).length;
                    neighborCounts[n].push(c);
                }
            }
            neighborCounts.push(neighborCounts.shift());
            for (n = 0; n < neighborCounts.length; n++) {
                if (1 <= neighborCounts[n].length) {
                    shuffle(neighborCounts[n]);
                    index = neighborCounts[n][0];
                    break;
                }
            }
            // trace("Model.corner: " + index + " table <" + table + ">");
            return index;
        }

        private function adjacents(table:Array, cursor:int, columnCount:int, rowCount:int):Array
        {
            var neighbors:Array = [];
            var neighbor:int;
            if (columnCount <= cursor) {
                neighbor = cursor - columnCount;
                if (EMPTY == table[neighbor]) {
                    neighbors.push(neighbor);
                }
            }
            if (cursor < rowCount * (columnCount - 1)) {
                neighbor = cursor + columnCount;
                if (EMPTY == table[neighbor]) {
                    neighbors.push(neighbor);
                }
            }
            if (1 <= cursor % columnCount) {
                neighbor = cursor - 1;
                if (EMPTY == table[neighbor]) {
                    neighbors.push(neighbor);
                }
            }
            if (cursor % columnCount < columnCount - 1) {
                neighbor = cursor + 1;
                if (EMPTY == table[neighbor]) {
                    neighbors.push(neighbor);
                }
            }
            return neighbors;
        }

        private function liberty(table:Array, cursor:int, columnCount:int, rowCount:int):int
        {
            var neighbors:Array = adjacents(table, cursor, columnCount, rowCount);
            if (neighbors.length == 0) {
                return -1;
            }
            else {
                shuffle(neighbors);
                return neighbors[0];
            }
        }

        private function shuffle(array:Array):void
        {
            for (var i:int = array.length - 1; 1 <= i; i--) {
                var j:int = (i + 1) * Math.random();
                var tmp:* = array[i];
                array[i] = array[j];
                array[j] = tmp;
            }
        }

        internal function indexAt(column:int, row:int):int
        {
            return row * columnCount + column;
        }

        /**
         * Just mouse down.  Select or deselect.
         */
        internal function select(i:int):Boolean
        {
            var push:Boolean;
            var index:int = selected.indexOf(i);
            if (index <= -1) {
                selected.push(i);
                if (null != onContagion) {
                    onContagion();
                }
                push = true;
            }
            else {
                selected.splice(index, 999);
                push = false;
                if (null != onDeselect) {
                    onDeselect();
                }
            }
            valid = updateValid();
            return push;
        }

        private function spell(selected:Array, letters:Array):String
        {
            var word:String = "";
            for (var s:int = 0; s < selected.length; s++) {
                word += letters[selected[s]];
            }
            return word;
        }

        private function updateValid():Boolean
        {
            valid = false;
            if (LETTER_MIN <= selected.length) {
                var word:String = spell(selected, table);
                if (Words.has(word)) {
                    // trace("Model.updateValid: word <" + word + ">");
                    valid = true;
                }
            }
            return valid;
        }

        /**
         * Removed addresses if 3 or more.
         * Set index to EMPTY and cell to null, in case view still refers to cell.
         */
        internal function judge():Array
        {
            var removed:Array = [];
            valid = updateValid();
            if (valid) {
                removed = selected.slice();
                // trace("Model.judge: removed " + removed);
                for each(var address:int in removed) {
                    removedLabels[address] = "correct_" + removed.length;
                    table[address] = EMPTY;
                }
                scoreUp(removed.length);
            }
            selected = [];
            valid = updateValid();
            return removed;
        }
   
        /**
         * 0, 0, 10, 20, 40,  80, 160, 320, 640, 1280, 2560, 5120, ...
         */
        private function scoreUp(length:int):void
        {
            kill += length;
            var points:int = Math.pow(2, length - 3);
            points *= 10;
            score += points;
            if (highScore < score) {
                highScore = score;
            }
            bonus(length);
        }

        private function bonus(length:int):void
        {
            if (null != onDie) {
                var bonus:int = 0;
                if (length <= Model.LETTER_MIN + 1) {
                    bonus = 0;
                }
                else if (length <= Model.LETTER_MIN + 2) {
                    bonus = 1;
                }
                else if (length <= Model.LETTER_MIN + 3) {
                    bonus = 2;
                }
                else if (length < Model.LETTER_MAX) {
                    bonus = 3;
                }
                else {
                    bonus = 4;
                }
                onDie(bonus);
            }
        }

        /**
         * Remove all cells.
         */
        internal function clear():void
        {
            removedLabels = populateRemovedLabels(cellCount);
            for (var i:int = 0; i < table.length; i++) {
                if (null != table[i]) {
                    table[i] = EMPTY;
                }
            }
        }

        internal function restartTrial():void
        {
            score = restartScore;
        }

        internal function update():int
        {
            return win();
        }

        /**
         * TODO: Lose if no moves remaining.
         * @return  0 continue, 1: win, -1: lose.
         */
        private function win():int
        {
            var winning:int = 0;
            if (maxKill <= kill) {
                winning = 1;
            }
            else if (occupied(table) < LETTER_MIN) {
                winning = -1;
            }
            return winning;
        }
        
        private function occupied(table:Array):int
        {
            var count:int = 0;
            for (var c:int = 0; c < table.length; c++) {
                if (EMPTY != table[c]) {
                    count++;
                }
            }
            return count;
        }
    }
}
