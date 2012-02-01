////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2003-2006 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.graphics
{
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Rectangle;

import mx.graphics.baseClasses.GraphicElement;

import mx.core.mx_internal;
import mx.events.PropertyChangeEvent;
import mx.filters.BaseFilter;
import mx.filters.IBitmapFilter;
import mx.graphics.IStroke;

use namespace mx_internal;

/**
 *  The StrokedElement class is the base class for all graphic elements that
 *  have a stroke.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class StrokedElement extends GraphicElement
{
    include "../core/Version.as";
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function StrokedElement()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  stroke
    //----------------------------------

    /**
     *  @private
     */
    mx_internal var _stroke:IStroke;
    
    [Bindable("propertyChange")]    
    [Inspectable(category="General")]

    /**
     *  The stroke used by this element.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get stroke():IStroke
    {
        return _stroke;
    }
    
    /**
     *  @private
     */
    public function set stroke(value:IStroke):void
    {
        var strokeEventDispatcher:EventDispatcher;
        var oldValue:IStroke = _stroke;
        
        strokeEventDispatcher = _stroke as EventDispatcher;
        if (strokeEventDispatcher)
            strokeEventDispatcher.removeEventListener(
                PropertyChangeEvent.PROPERTY_CHANGE, 
                stroke_propertyChangeHandler);
            
        _stroke = value;
        
        strokeEventDispatcher = _stroke as EventDispatcher;
        if (strokeEventDispatcher)
            strokeEventDispatcher.addEventListener(
                PropertyChangeEvent.PROPERTY_CHANGE, 
                stroke_propertyChangeHandler);
     
     	dispatchPropertyChangeEvent("stroke", oldValue, _stroke);
     
        invalidateDisplayList();
        // Parent layout takes stroke into account
        invalidateParentSizeAndDisplayList();
    }
    
    //--------------------------------------------------------------------------
    //
	//  overriden methods from GraphicElement
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override protected function updateDisplayList(unscaledWidth:Number, 
                                                  unscaledHeight:Number):void
    {
        //trace("StrokedElement.updateDisplayList w",unscaledWidth,"h",unscaledHeight,"drawnDisplayObject",drawnDisplayObject,"this",this);                                                     
        if (!drawnDisplayObject || !(drawnDisplayObject is Sprite))
            return;
            
        // The base GraphicElement class has cleared the graphics for us.    
        var g:Graphics = (drawnDisplayObject as Sprite).graphics;

        beginDraw(g);
        drawElement(g);
        endDraw(g);
    }
            
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Set up the drawing for this element. This is the first of three steps
     *  taken during the drawing process. In this step, the stroke properties
     *  are applied.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function beginDraw(g:Graphics):void
    {
        if (stroke)
            stroke.draw(g,new Rectangle(measuredX, measuredY, width, height));
        else
            g.lineStyle();
            
        // Even though this is a stroked element, we still need to beginFill/endFill
        // otherwise subsequent fills could get messed up.
        g.beginFill(0, 0);
    }
    
    /**
     *  Draw the element. This is the second of three steps taken during the drawing
     *  process. Override this method to implement your drawing. The stroke
     *  (and fill, if applicable) have been set in the <code>beginDraw()</code> method. 
     *  Your override should only contain calls to drawing methods such as 
     *  <code>moveTo()</code>, <code>curveTo()</code>, and <code>drawRect()</code>.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function drawElement(g:Graphics):void
    {
        // override to do your drawing
    }
    
    /**
     *  Finalize drawing for this element. This is the final of the three steps taken
     *  during the drawing process. In this step, fills are closed.
     *  
     *  @param g The graphics element to finish drawing.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    protected function endDraw(g:Graphics):void
    {
        g.endFill();
    }
    
    override protected function getStroke():IStroke
    {
        return stroke;
    }
    
    //--------------------------------------------------------------------------
    //
    //  EventHandlers
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    protected function stroke_propertyChangeHandler(event:PropertyChangeEvent):void
    {
        invalidateDisplayList();
        switch (event.property)
        {
            case "weight":
            case "scaleMode":
                // Parent layout takes stroke weight into account
                invalidateParentSizeAndDisplayList();
            break;
        }
    }

}

}
