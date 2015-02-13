package com.finegamedesign.spellstone
{
    import flash.media.Sound;
    import flash.media.SoundChannel;

    /**
     * Connect.  Hear next note.
     * Misconnect.  Hear higher note.
     * 2014-08-26 Erin McCarty was reminded of Osu.
     */
    internal final class Sounds
    {
        internal static var instance:Sounds;

        [Embed(source="../../../../sfx/kalimba_a3_f4.mp3")]
        private static var kalimba_a3_f4Class:Class;
        internal var kalimba_a3_f4:Sound = new kalimba_a3_f4Class();

        [Embed(source="../../../../sfx/kalimba_c4.mp3")]
        private static var kalimba_c4Class:Class;
        internal var kalimba_c4:Sound = new kalimba_c4Class();

        [Embed(source="../../../../sfx/kalimba_d4.mp3")]
        private static var kalimba_d4Class:Class;
        internal var kalimba_d4:Sound = new kalimba_d4Class();

        [Embed(source="../../../../sfx/kalimba_d5.mp3")]
        private static var kalimba_d5Class:Class;
        internal var kalimba_d5:Sound = new kalimba_d5Class();

        [Embed(source="../../../../sfx/kalimba_e4.mp3")]
        private static var kalimba_e4Class:Class;
        internal var kalimba_e4:Sound = new kalimba_e4Class();

        [Embed(source="../../../../sfx/kalimba_g3.mp3")]
        private static var kalimba_g3Class:Class;
        internal var kalimba_g3:Sound = new kalimba_g3Class();

        [Embed(source="../../../../sfx/silence.mp3")]
        private static var silenceClass:Class;
        private var silence:Sound = new silenceClass();
        private var silenceChannel:SoundChannel;

        private var notes:Object;
        private var sonata:Array;
        private var sonataIndex:int;

        /**
         * To prevent sound manager from sleeping, loop silence.
         * Notes of "Random Repeat Sonata" flute part composed by Jade Brewer, 2013.
         */
        public function Sounds()
        {
            notes = {
                a3_f4: kalimba_a3_f4,
                c4: kalimba_c4, 
                d4: kalimba_d4, 
                d5: kalimba_d5, 
                e4: kalimba_e4,
                g3: kalimba_g3
            };
            include "Sonata.as"
            sonataIndex = 0;
            if (null != instance) {
                instance.silenceChannel.stop();
            }
            silenceChannel = silence.play(0, int.MAX_VALUE);
        }

        internal function correct():void
        {
            notes[sonata[sonataIndex]].play();
            sonataIndex = (sonataIndex + 1) % sonata.length;
        }

        internal function reverse():void
        {
            sonataIndex = (sonataIndex - 1) % sonata.length;
            notes[sonata[sonataIndex]].play();
            sonataIndex = (sonataIndex - 1) % sonata.length;
        }

        internal function wrong():void
        {
            notes.d5.play();
        }
    }
}
