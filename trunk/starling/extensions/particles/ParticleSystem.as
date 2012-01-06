// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions.particles
{
    import com.adobe.utils.AGALMiniAssembler;
    
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.VertexBuffer3D;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.animation.IAnimatable;
    import starling.core.RenderSupport;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.errors.MissingContextError;
    import starling.events.Event;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    public class ParticleSystem extends DisplayObject implements IAnimatable
    {
        private var mTexture:Texture;
        private var mParticles:Vector.<Particle>;
        private var mFrameTime:Number;
        
        private var mVertexData:VertexData;
        private var mVertexBuffer:VertexBuffer3D;
        
        private var mIndices:Vector.<uint>;
        private var mIndexBuffer:IndexBuffer3D;
        
        private var mNumParticles:int;
        private var mEmissionRate:Number; // emitted particles per second
        private var mEmissionTime:Number;
                
        /** Helper object. */
        private static var sRenderAlpha:Vector.<Number> = new <Number>[1.0, 1.0, 1.0, 1.0];
        
        protected var mEmitterX:Number;
        protected var mEmitterY:Number;
        protected var mPremultipliedAlpha:Boolean;
        protected var mBlendFactorSource:String;     
        protected var mBlendFactorDestination:String;
        
        public function ParticleSystem(texture:Texture, emissionRate:Number, 
                                       initialCapacity:int=128,
                                       blendFactorSource:String=null, blendFactorDest:String=null)
        {
            if (texture == null) throw new ArgumentError("texture must not be null");
            
            mTexture = texture;
            mPremultipliedAlpha = texture.premultipliedAlpha;
            mParticles = new Vector.<Particle>(0, false);
            mVertexData = new VertexData(0, mPremultipliedAlpha);
            mIndices = new <uint>[];
            mEmissionRate = emissionRate;
            mEmissionTime = 0.0;
            mFrameTime = 0.0;
            mEmitterX = mEmitterY = 0;
            
            mBlendFactorDestination = blendFactorDest || Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            mBlendFactorSource = blendFactorSource ||
                (mPremultipliedAlpha ? Context3DBlendFactor.ONE : Context3DBlendFactor.SOURCE_ALPHA);
            
            registerProgram(texture.mipMapping);
            raiseCapacity(initialCapacity);
        }
        
        public override function dispose():void
        {
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            super.dispose();
        }
        
        protected function createParticle():Particle
        {
            return new Particle();
        }
        
        protected function initParticle(particle:Particle):void
        {
            particle.x = mEmitterX;
            particle.y = mEmitterY;
            particle.currentTime = 0;
            particle.totalTime = 1;
            particle.color = Math.random() * 0xffffff;
        }

        protected function advanceParticle(particle:Particle, passedTime:Number):void
        {
            particle.y += passedTime * 250;
            particle.alpha = 1.0 - particle.currentTime / particle.totalTime;
            particle.scale = 1.0 - particle.alpha; 
            particle.currentTime += passedTime;
        }
        
        private function raiseCapacity(byAmount:int):void
        {
            var oldCapacity:int = capacity;
            var newCapacity:int = capacity + byAmount;
            var context:Context3D = Starling.context;

            if (context == null) throw new MissingContextError();
            
            var baseVertexData:VertexData = new VertexData(4);
            baseVertexData.setTexCoords(0, 0.0, 0.0);
            baseVertexData.setTexCoords(1, 1.0, 0.0);
            baseVertexData.setTexCoords(2, 0.0, 1.0);
            baseVertexData.setTexCoords(3, 1.0, 1.0);
            mTexture.adjustVertexData(baseVertexData, 0, 4);
            
            mParticles.fixed = false;
            mIndices.fixed = false;
            
            for (var i:int=oldCapacity; i<newCapacity; ++i)  
            {
                var numVertices:int = i * 4;
                mParticles.push(createParticle());
                mVertexData.append(baseVertexData);
                mIndices.push(numVertices,     numVertices + 1, numVertices + 2, 
                              numVertices + 1, numVertices + 3, numVertices + 2);
            }
            
            mParticles.fixed = true;
            mIndices.fixed = true;
            
            // upload data to vertex and index buffers
            
            if (mVertexBuffer) mVertexBuffer.dispose();
            if (mIndexBuffer)  mIndexBuffer.dispose();
            
            mVertexBuffer = context.createVertexBuffer(newCapacity * 4, VertexData.ELEMENTS_PER_VERTEX);
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, newCapacity * 4);
            
            mIndexBuffer  = context.createIndexBuffer(newCapacity * 6);
            mIndexBuffer.uploadFromVector(mIndices, 0, newCapacity * 6);
        }
        
        public function start(duration:Number=Number.MAX_VALUE):void
        {
            if (mEmissionRate != 0)                
                mEmissionTime = duration;
        }
        
        public function stop():void
        {
            mEmissionTime = 0.0;
        }
        
        public override function getBounds(targetSpace:DisplayObject):Rectangle
        {
            var matrix:Matrix = getTransformationMatrix(targetSpace);
            var position:Point = matrix.transformPoint(new Point(x, y));
            return new Rectangle(position.x, position.y);
        }
        
        public function advanceTime(passedTime:Number):void
        {
            passedTime = Math.min(0.2, passedTime);
            
            var particleIndex:int = 0;
            var particle:Particle;
            
            // advance existing particles
            
            while (particleIndex < mNumParticles)
            {
                particle = mParticles[particleIndex] as Particle;
                
                if (particle.currentTime < particle.totalTime)
                {
                    advanceParticle(particle, passedTime);
                    ++particleIndex;
                }
                else
                {
                    if (particleIndex != mNumParticles - 1)
                    {
                        var nextParticle:Particle = mParticles[mNumParticles - 1] as Particle;
                        mParticles[mNumParticles-1] = particle;
                        mParticles[particleIndex] = nextParticle;
                    }
                    
                    --mNumParticles;
                    
                    if (mNumParticles == 0)
                        dispatchEvent(new Event("complete")); // TODO: use "Event.COMPLETE"
                                              // when it's available in an official release
                }
            }
            
            // create and advance new particles
            
            if (mEmissionTime > 0)
            {
                var timeBetweenParticles:Number = 1.0 / mEmissionRate;
                mFrameTime += passedTime;
                
                while (mFrameTime > 0)
                {
                    if (mNumParticles == capacity)
                        raiseCapacity(capacity);
                    
                    particle = mParticles[mNumParticles++] as Particle;
                    initParticle(particle);
                    advanceParticle(particle, mFrameTime);
                    
                    mFrameTime -= timeBetweenParticles;
                }
                
                if (mEmissionTime != Number.MAX_VALUE)
                    mEmissionTime = Math.max(0.0, mEmissionTime - passedTime);
            }
            
            // update vertex data
            
            var vertexID:int = 0;
            var color:uint;
            var alpha:Number;
            var x:Number, y:Number;
            var xOffset:Number, yOffset:Number;
            var textureWidth:Number = mTexture.width;
            var textureHeight:Number = mTexture.height;
            
            for (var i:int=0; i<mNumParticles; ++i)
            {
                vertexID = i << 2;
                particle = mParticles[i] as Particle;
                color = particle.color;
                alpha = particle.alpha;
                x = particle.x;
                y = particle.y;
                xOffset = textureWidth  * particle.scale >> 1;
                yOffset = textureHeight * particle.scale >> 1;
                
                for (var j:int=0; j<4; ++j)
                    mVertexData.setColor(vertexID+j, color, alpha);
                
                mVertexData.setPosition(vertexID,   x - xOffset, y - yOffset);
                mVertexData.setPosition(vertexID+1, x + xOffset, y - yOffset);
                mVertexData.setPosition(vertexID+2, x - xOffset, y + yOffset);
                mVertexData.setPosition(vertexID+3, x + xOffset, y + yOffset);
                
                // todo: add rotation
            }
        }
        
        public override function render(support:RenderSupport, alpha:Number):void
        {
            if (mNumParticles == 0) return;
            
            // always call this method when you write custom rendering code!
            // it causes all previously batched quads/images to render.
            support.finishQuadBatch();
            
            alpha *= this.alpha;
            
            var program:String = getProgramName(mTexture.mipMapping);
            var context:Context3D = Starling.context;
            var pma:Boolean = texture.premultipliedAlpha;
            
            sRenderAlpha[0] = sRenderAlpha[1] = sRenderAlpha[2] = pma ? alpha : 1.0;
            sRenderAlpha[3] = alpha;
            
            if (context == null) throw new MissingContextError();
            
            mVertexBuffer.uploadFromVector(mVertexData.rawData, 0, mNumParticles * 4);
            mIndexBuffer.uploadFromVector(mIndices, 0, mNumParticles * 6);
            
            context.setBlendFactors(mBlendFactorSource, mBlendFactorDestination);
            
            context.setProgram(Starling.current.getProgram(program));
            context.setTextureAt(0, mTexture.base);
            context.setVertexBufferAt(0, mVertexBuffer, VertexData.POSITION_OFFSET, Context3DVertexBufferFormat.FLOAT_3); 
            context.setVertexBufferAt(1, mVertexBuffer, VertexData.COLOR_OFFSET,    Context3DVertexBufferFormat.FLOAT_4);
            context.setVertexBufferAt(2, mVertexBuffer, VertexData.TEXCOORD_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, support.mvpMatrix, true);            
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sRenderAlpha, 1);
            context.drawTriangles(mIndexBuffer, 0, mNumParticles * 2);
            
            context.setTextureAt(0, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }
        
        // program management
        
        private static function registerProgram(mipmap:Boolean):void
        {
            var target:Starling = Starling.current;
            var programName:String = getProgramName(mipmap);
            
            if (target.hasProgram(programName)) return; // already registered
            
            // create vertex and fragment programs - from assembly.            
            
            var textureOptions:String = "2d, clamp, linear, " + (mipmap ? "mipnearest" : "mipnone"); 
            
            var vertexProgramCode:String =
                "m44 op, va0, vc0 \n" + // 4x4 matrix transform to output clipspace
                "mov v0, va1      \n" + // pass color to fragment program
                "mov v1, va2      \n";  // pass texture coordinates to fragment program
            
            var fragmentProgramCode:String =
                "tex ft1, v1, fs0 <" + textureOptions + "> \n" + // sample texture 0
                "mul ft2, ft1, v0                          \n" + // multiply color with texel color
                "mul oc, ft2, fc0                          \n";   // multiply color with alpha
            
            var vertexProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            vertexProgramAssembler.assemble(Context3DProgramType.VERTEX, vertexProgramCode);
            
            var fragmentProgramAssembler:AGALMiniAssembler = new AGALMiniAssembler();
            fragmentProgramAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentProgramCode);
            
            target.registerProgram(programName, vertexProgramAssembler.agalcode,
                                                fragmentProgramAssembler.agalcode);
        }

        private static function getProgramName(mipmap:Boolean):String
        {
            return mipmap ? "PS_mm" : "PS_nm";
        }
        
        public function get isComplete():Boolean
        {
            // This method just tells the juggler if the particle system is finished and can be 
            // removed. Since the PS can be restarted, it should never be removed automatically.
            
            return false;
        }
        
        public function get capacity():int { return mVertexData.numVertices / 4; }
        public function get numParticles():int { return mNumParticles; }
        
        public function get emissionRate():Number { return mEmissionRate; }
        public function set emissionRate(value:Number):void { mEmissionRate = value; }
        
        public function get emitterX():Number { return mEmitterX; }
        public function set emitterX(value:Number):void { mEmitterX = value; }
        
        public function get emitterY():Number { return mEmitterY; }
        public function set emitterY(value:Number):void { mEmitterY = value; }
        
        public function get texture():Texture { return mTexture; }
    }
}