package com.finegamedesign.spellstone
{
    public class Words
    {
        internal static var lists:Array;

        private static var hash:Object;
        /*--*/
        [Embed(source="../../../../txt/word_list_moby_crossword.flat.txt", mimeType="application/octet-stream")]
        private static const AllWordList:Class;
        //-*/
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_1.txt", mimeType="application/octet-stream")]
        private static const Grade1List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_2.txt", mimeType="application/octet-stream")]
        private static const Grade2List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_3.txt", mimeType="application/octet-stream")]
        private static const Grade3List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_4.txt", mimeType="application/octet-stream")]
        private static const Grade4List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_5.txt", mimeType="application/octet-stream")]
        private static const Grade5List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_6.txt", mimeType="application/octet-stream")]
        private static const Grade6List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_7.txt", mimeType="application/octet-stream")]
        private static const Grade7List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_spelling_grade_8.txt", mimeType="application/octet-stream")]
        private static const Grade8List:Class;
        [Embed(source="../../../../txt/bigiqkids.com_wordlist_vocabulary_sat.txt", mimeType="application/octet-stream")]
        private static const Grade9List:Class;

        internal static function init():void
        {
            if (null == hash) {
                hash = 
                        //- WordHash.hash;
                        constructHash(String(new AllWordList()));
            }
            if (null == lists) {
                lists = [["PLAY"]];
                lists.push(array(String(new Grade1List())));
                lists.push(array(String(new Grade2List())));
                lists.push(array(String(new Grade3List())));
                lists.push(array(String(new Grade4List())));
                lists.push(array(String(new Grade5List())));
                lists.push(array(String(new Grade6List())));
                lists.push(array(String(new Grade7List())));
                lists.push(array(String(new Grade8List())));
                lists.push(array(String(new Grade9List())));
            }
        }

        internal static function has(word:String):Boolean
        {
            if (word in hash) {
                return true;
            }
            else {
                return false;
            }
        }

        private static function constructHash(wordList:String):Object
        {
            var hash:Object = {};
            var list:Array = array(wordList);
            for (var w:int = 0; w < list.length; w++) {
                hash[list[w]] = true;
            }
            trace("Words.parse: " + list.length + " words");
            return hash;
        }

        /**
         * Multiple words parsed separately.
         */
        private static function array(wordList:String):Array
        {
            return wordList.replace(/\r\n/g, "\n").replace(" ", "\n").split("\n");
        }
    }
}
