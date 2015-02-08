package com.finegamedesign.spellstone
{
    import flash.display.DisplayObjectContainer;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;

    public class View
    {
        internal var model:Model;
        internal var originalRoomHeight:int = -1;
        internal var originalRoomWidth:int = -1;
        internal var originalTileWidth:int = 80;
        internal var room:DisplayObjectContainer;
        internal var scale:Number;
        internal var tileWidth:int;
        internal var table:Array;
        private var isMouseDown:Boolean;
        private var mouseJustPressed:Boolean;
        private var ui:Main;

        public function View()
        {
            table = [];
        }

        /**
         * Position each object in the model's grid into the center-aligned room and scale to fit in room.
         * Adds property "model" to each cell in table.
         */
        internal function populate(model:Model, room:DisplayObjectContainer, ui:Main):void
        {
            this.model = model;
            this.room = room;
            this.ui = ui;
            if (originalRoomWidth <= 0) {
                originalTileWidth = new LetterTile().width;
                originalRoomHeight = room.height;
                originalRoomWidth = room.width;
            }
            var heightPerTile:int = originalRoomHeight / model.rowCount;
            var widthPerTile:int = originalRoomWidth / model.columnCount;
            if (heightPerTile < widthPerTile) {
                tileWidth = heightPerTile;
            }
            else {
                tileWidth = widthPerTile;
            }
            scale = tileWidth / originalTileWidth;
            // room.width = model.columnCount * tileWidth;
            // room.height = model.rowCount * tileWidth;
            table = [];
            for (var i:int = 0; i < model.table.length; i++){
                var cell:LetterTile = new LetterTile();
                cell.scaleX = scale;
                cell.scaleY = scale;
                cell.txt.mouseEnabled = false;
                cell.name = "cell_" + i.toString();
                room.addChild(cell);
                table.push(cell);
            }
            updateCells(model, table);
            room.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
            ui.submit.addEventListener(MouseEvent.CLICK, judge, false, 0, true);
        }

        private function position(mc:MovieClip, i:int, columnCount:int, rowCount:int):void
        {
            mc.x = positionX(i, columnCount);
            mc.y = positionY(i, columnCount, rowCount);
        }

        private function positionX(i:int, columnCount:int):Number
        {
            var column:int = i % columnCount;
            return tileWidth * (0.5 + column - columnCount * 0.5);
        }

        private function positionY(i:int, columnCount:int, rowCount:int):Number
        {
            var row:int = i / columnCount;
            return tileWidth * (0.5 + row - rowCount * 0.5);
        }

        internal function columnAt(roomX:Number, columnCount):int
        {
            return roomX / tileWidth + columnCount * 0.5;
        }

        internal function rowAt(roomY:Number, rowCount:int):int
        {
            return roomY / tileWidth + rowCount * 0.5;
        }

        private function mouseDown(event:MouseEvent):void
        {
            mouseJustPressed = !isMouseDown;
            isMouseDown = true;
        }

        private function mouseUp(event:MouseEvent):void
        {
            mouseJustPressed = false;
            isMouseDown = false;
        }

        private function selectDown(e:MouseEvent):void
        {
            mouseDown(e);
            select(e);
        }

        /**
         * Only need to update one cell, not all cells.
         */
        private function select(e:MouseEvent):void
        {
            if (!isMouseDown) {
                return;
            }
            var mc:MovieClip = MovieClip(e.currentTarget);
            var index:int = parseInt(mc.name.split("_")[1]);
            // trace("View.select: index " + index);
            var selected:Boolean = model.select(index);
            updateCells(model, table);
        }

        internal function update():void
        {
            updateCells(model, table);
        }

        private function updateCells(model:Model, table:Array):void
        {
            for (var t:int = 0; t < table.length; t++) {
                var cell:LetterTile = table[t];
                cell.txt.text = model.table[t];
                var label:String = 
                    Model.EMPTY == model.table[t]
                    ? model.removedLabels[t]
                    :  (0 <= model.selected.indexOf(t) 
                        ? "select"
                        : "enable");
                var changed:Boolean = false;
                if (cell.currentLabel != label) {
                    changed = true;
                    cell.gotoAndPlay(label);
                }
                position(cell, t, model.columnCount, model.rowCount);
                if (changed) {
                    if (Model.EMPTY == model.table[t] || model.removedLabels[t].indexOf("correct_") == 0) {
                        cell.removeEventListener(MouseEvent.MOUSE_DOWN, selectDown);
                        cell.buttonMode = false;
                    }
                    else {
                        cell.buttonMode = true;
                        cell.addEventListener(MouseEvent.MOUSE_DOWN, selectDown, false, 0, true);
                    }
                }
            }
            updateSelected(ui, model.selected);
        }

        private function updateSelected(ui:Main, selected:Array):void
        {
            for (var i:int = 0; i < Model.LETTER_MAX; i++) {
                var selection:LetterTile = ui["selected_" + i].tile;
                var label:String =  i < selected.length
                                    ? "select" 
                                    : "none";
                if (selection.currentLabel != label) {
                    selection.gotoAndPlay(label);
                }
                var text:String = i < selected.length 
                                  ? model.table[selected[i]] 
                                  : Model.EMPTY;
                selection.txt.text = text;
            }
            ui.submit.visible = model.valid;
        }

        /**
         * Remove cells corresponding to model's addresses.
         */
        private function judge(e:MouseEvent):void
        {
            model.judge();
            updateCells(model, table);
        }

        internal function clear():void
        {
            model.clear();
            updateCells(model, table);
            for (var t:int = table.length - 1; 0 <= t; t--) {
                var mc:MovieClip = table[t];
                mc.gotoAndPlay("none");
                if (room.contains(mc)) {
                    room.removeChild(mc);
                }
                table.splice(t, 1);
            }
            for (var c:int = room.numChildren - 1; 0 <= c; c--) {
                if (room.getChildAt(c) is LetterTile) {
                    room.removeChild(room.getChildAt(c));
                }
            }
        }
    }
}
