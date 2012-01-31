////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.components 
{

import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.geom.Rectangle;

import mx.components.baseClasses.GroupBase;
import mx.core.Container;
import mx.core.ILayoutElement;
import mx.core.IUITextField;
import mx.core.IVisualElement;
import mx.core.IVisualElementContainer;
import mx.core.mx_internal;
import mx.events.ElementExistenceEvent;
import mx.graphics.IGraphicElement;
import mx.graphics.ISharedDisplayObject;
import mx.graphics.baseClasses.ISharedGraphicsDisplayObject;
import mx.graphics.baseClasses.TextGraphicElement;
import mx.layout.LayoutBase;
import mx.layout.LayoutElementFactory;
import mx.styles.ISimpleStyleClient;
import mx.styles.IStyleClient;
import mx.styles.StyleProtoChain;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when a visual element is added to the content holder.
 *  <code>event.element</code> is the visual element that was added.
 *
 *  @eventType mx.events.ElementExistenceEvent.ELEMENT_ADD
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Event(name="elementAdd", type="mx.events.ElementExistenceEvent")]

/**
 *  Dispatched when a visual element is removed to the content holder.
 *  <code>event.element</code> is the visual element that's being removed.
 *
 *  @eventType mx.events.ElementExistenceEvent.ELEMENT_REMOVE
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
[Event(name="elementRemove", type="mx.events.ElementExistenceEvent")]

//--------------------------------------
//  Excluded APIs
//--------------------------------------

[Exclude(name="addChild", kind="method")]
[Exclude(name="addChildAt", kind="method")]
[Exclude(name="removeChild", kind="method")]
[Exclude(name="removeChildAt", kind="method")]
[Exclude(name="setChildIndex", kind="method")]
[Exclude(name="swapChildren", kind="method")]
[Exclude(name="swapChildrenAt", kind="method")]

//--------------------------------------
//  Other metadata
//--------------------------------------

[ResourceBundle("components")]

[DefaultProperty("mxmlContent")] 

[IconFile("Group.png")]

/**
 *  The Group class is the base container class for visual elements.
 *
 *  @see mx.components.DataGroup
 *
 *  @includeExample examples/GroupExample.mxml
 *
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class Group extends GroupBase implements IVisualElementContainer, ISharedGraphicsDisplayObject
{
    /**
     *  Constructor.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function Group(layout:LayoutBase = null):void
    {
        super(layout);    
    }

	//--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var needsDisplayObjectAssignment:Boolean = false;
    private var layeringMode:uint = ITEM_ORDERED_LAYERING;
    private var numGraphicElements:uint = 0;
    
    private static const ITEM_ORDERED_LAYERING:uint = 0;
    private static const SPARSE_LAYERING:uint = 1;    

    //--------------------------------------------------------------------------
    //
    //  Overridden properties
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override public function set resizeMode(stringValue:String):void
    {
    	if (isValidScaleGrid())
        {
        	// Force the resize mode to be scale if we 
        	// have set scaleGrid properties
        	stringValue = ResizeMode.SCALE;
        }
         
    	super.resizeMode = stringValue;
    }
    
    /**
     *  @private
     */
    override public function set scrollRect(value:Rectangle):void
    {
        // Work-around for Flash Player bug: if GraphicElements share
        // the Group's Display Object and cacheAsBitmap is true, the
        // scrollRect won't function correctly. 
        var previous:Boolean = canShareDisplayObject;
        super.scrollRect = value;
        if (numGraphicElements > 0 && previous != canShareDisplayObject)
            invalidateDisplayObjectOrdering();            
    }

	//--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  alpha
    //----------------------------------

    [Inspectable(defaultValue="1.0", category="General", verbose="1")]

    /**
     *  @private
     */
    override public function set alpha(value:Number):void
    {
        if (super.alpha == value)
            return;
        
        //The default blendMode in FXG is 'layer'. There are only
        //certain cases where this results in a rendering difference,
        //one being when the alpha of the Group is > 0 and < 1. In that
        //case we set the blendMode to layer to avoid the performance
        //overhead that comes with a non-normal blendMode. 
        
        if (value > 0 && value < 1 && !blendModeExplicitlySet)
        {
            if (_blendMode != BlendMode.LAYER)
            {
                _blendMode = BlendMode.LAYER;
                blendModeChanged = true;
                invalidateDisplayObjectOrdering();
                invalidateProperties();
            }
        }
        else if ((value == 1 || value == 0) && !blendModeExplicitlySet)
        {
            if (_blendMode != BlendMode.NORMAL)
            {
                _blendMode = BlendMode.NORMAL;
                blendModeChanged = true;
                invalidateDisplayObjectOrdering();
                invalidateProperties();
            }
        }
            
        super.alpha = value;
    }
    
    //----------------------------------
    //  blendMode
    //----------------------------------
    
    /**
     *  @private
     *  Storage for the blendMode property.
     */
    private var _blendMode:String = BlendMode.NORMAL;
    private var blendModeChanged:Boolean;
    private var blendModeExplicitlySet:Boolean;

    [Inspectable(category="General", enumeration="add,alpha,darken,difference,erase,hardlight,invert,layer,lighten,multiply,normal,subtract,screen,overlay", defaultValue="normal")]

    /**
     *  A value from the BlendMode class that specifies which blend mode to use. 
     *  A bitmap can be drawn internally in two ways. 
     *  If you have a blend mode enabled or an external clipping mask, the bitmap is drawn 
     *  by adding a bitmap-filled square shape to the vector render. 
     *  If you attempt to set this property to an invalid value, 
     *  Flash Player or Adobe AIR sets the value to <code>BlendMode.NORMAL</code>. 
     *
     *  @default BlendMode.NORMAL
     *
     *  @see flash.display.DisplayObject#blendMode
     *  @see flash.display.BlendMode
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function get blendMode():String
    {
        if (blendModeExplicitlySet)
            return _blendMode;
        else return BlendMode.LAYER;
    }
    
    /**
     *  @private
     */
    override public function set blendMode(value:String):void
    {
        if (blendModeExplicitlySet && value == _blendMode)
            return;
            
        var oldValue:String = _blendMode;
        _blendMode = value;
            
        blendModeExplicitlySet = true;
        
        blendModeChanged = true;
        
        // Only need to re-do display object assignment if blendmode was normal
        // and is changing to someting else, or the blend mode was something else 
        // and is going back to normal.  This is because display object sharing
        // only happens when blendMode is normal.
        if ((oldValue == BlendMode.NORMAL || value == BlendMode.NORMAL) && 
            !(oldValue == BlendMode.NORMAL && value == BlendMode.NORMAL))
        {
            invalidateDisplayObjectOrdering();
        }
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  mxmlContent
    //----------------------------------
    
    private var mxmlContentChanged:Boolean = false;
    private var _mxmlContent:Array;
    
    [ArrayElementType("mx.core.IVisualElement")]
    
    /**
     *  Visual content children for this Group.
     *
     *  <p>The content items should only be IVisualItems.  An 
     *  mxmlContent Array shouldn't be shared between multiple
     *  Groups as visual elements can only live in one Group at 
     *  a time.</p>
     * 
     *  <p>If the content is an Array, do not modify the array 
     *  directly. Use the methods defined on Group to do this.</p>
     *
     *  @default null
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get mxmlContent():Array
    {
        if (_mxmlContent)
            return _mxmlContent.concat();
        else
            return null;
    }
    
    /**
     *  @private
     */
    public function set mxmlContent(value:Array):void
    {
        if (createChildrenCalled)
        {
            setMXMLContent(value);
        }
        else
        {
            mxmlContentChanged = true;
            _mxmlContent = value;
            // we will validate this in createChildren();
        }
    }
    

    /**
     *  @private
     *  Adds the elements in <code>mxmlContent</code> to the Group.
     *  Flex calls this method automatically; you do not call it directly.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */ 
    private function setMXMLContent(value:Array):void
    {
        var i:int;
        
        // if there's old content and it's different than what 
        // we're trying to set it to, then let's remove all the old 
        // elements first.
        if (_mxmlContent != null && _mxmlContent != value)
        {
            for (i = _mxmlContent.length - 1; i >= 0; i--)
            {
                elementRemoved(_mxmlContent[i], i);
            }
        }
        
        _mxmlContent = (value) ? value.concat() : null;  // defensive copy
        
        if (_mxmlContent != null)
        {
            var n:int = _mxmlContent.length;
            for (i = 0; i < n; i++)
            {   
                var elt:IVisualElement = _mxmlContent[i];

                // A common mistake is to bind the viewport property of an FxScroller
                // to a group that was defined in the MXML file with a different parent    
                if (elt.parent && (elt.parent != this))
                    throw new Error(resourceManager.getString("components", "mxmlElementNoMultipleParents", [elt]));

                elementAdded(elt, i);
            }
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties: ScaleGrid
    //
    //--------------------------------------------------------------------------

    private var scaleGridChanged:Boolean = false;
    
    // store the scaleGrid into a rectangle to save space (top, left, bottom, right);
    private var scaleGridStorageVariable:Rectangle;

	//----------------------------------
    //  scale9Grid
    //----------------------------------
    
    /**
     *  @private
     */
    override public function set scale9Grid(value:Rectangle):void
	{
		if (value != null)
		{
			scaleGridTop = value.top;
			scaleGridBottom = value.bottom;
			scaleGridLeft = value.left;
			scaleGridRight = value.right;
		}
		else
		{
			scaleGridTop = NaN;
			scaleGridBottom = NaN;
			scaleGridLeft = NaN;
			scaleGridRight = NaN;
		}
	}

    //----------------------------------
    //  scaleGridBottom
    //----------------------------------
    
    [Inspectable(category="General")]
    
    /**
     * Specfies the bottom coordinate of the scale grid.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get scaleGridBottom():Number
    {
        if (scaleGridStorageVariable)
            return scaleGridStorageVariable.height;
        
        return NaN;
    }
    
    public function set scaleGridBottom(value:Number):void
    {
        if (!scaleGridStorageVariable)
            scaleGridStorageVariable = new Rectangle(NaN, NaN, NaN, NaN);
        
        if (value != scaleGridStorageVariable.height)
        {
            scaleGridStorageVariable.height = value;
            scaleGridChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }
    }
    
    //----------------------------------
    //  scaleGridLeft
    //----------------------------------
    
    [Inspectable(category="General")]
    
    /**
     * Specfies the left coordinate of the scale grid.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get scaleGridLeft():Number
    {
        if (scaleGridStorageVariable)
            return scaleGridStorageVariable.x;
        
        return NaN;
    }
    
    public function set scaleGridLeft(value:Number):void
    {
        if (!scaleGridStorageVariable)
            scaleGridStorageVariable = new Rectangle(NaN, NaN, NaN, NaN);
        
        if (value != scaleGridStorageVariable.x)
        {
            scaleGridStorageVariable.x = value;
            scaleGridChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }

    }

    //----------------------------------
    //  scaleGridRight
    //----------------------------------
    
    [Inspectable(category="General")]
    
    /**
     * Specfies the right coordinate of the scale grid.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get scaleGridRight():Number
    {
        if (scaleGridStorageVariable)
            return scaleGridStorageVariable.width;
        
        return NaN;
    }
    
    public function set scaleGridRight(value:Number):void
    {
        if (!scaleGridStorageVariable)
            scaleGridStorageVariable = new Rectangle(NaN, NaN, NaN, NaN);
        
        if (value != scaleGridStorageVariable.width)
        {
            scaleGridStorageVariable.width = value;
            scaleGridChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }

    }

    //----------------------------------
    //  scaleGridTop
    //----------------------------------
    
    [Inspectable(category="General")]
    
    /**
     * Specfies the top coordinate of the scale grid.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get scaleGridTop():Number
    {
        if (scaleGridStorageVariable)
            return scaleGridStorageVariable.y;
        
        return NaN;
    }
    
    public function set scaleGridTop(value:Number):void
    {
        if (!scaleGridStorageVariable)
            scaleGridStorageVariable = new Rectangle(NaN, NaN, NaN, NaN);
        
        if (value != scaleGridStorageVariable.y)
        {
            scaleGridStorageVariable.y = value;
            scaleGridChanged = true;
            invalidateProperties();
            invalidateDisplayList();
        }
    } 
    
    private function isValidScaleGrid():Boolean
    {
    	return !isNaN(scaleGridLeft) &&
        	   !isNaN(scaleGridTop) &&
        	   !isNaN(scaleGridRight) &&
        	   !isNaN(scaleGridBottom);
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     *  Whether createChildren() has been called or not.
     *  We use this in the setter for mxmlContent to know 
     *  whether to validate the value immediately, or just 
     *  wait to let createChildren() do it.
     */
    private var createChildrenCalled:Boolean = false;
    
    /**
     *  @private
     */ 
    override protected function createChildren():void
    {
        super.createChildren();
        
        createChildrenCalled = true;
        
        if (mxmlContentChanged)
        {
            mxmlContentChanged = false;
            setMXMLContent(_mxmlContent);
        }
    }
    
    /**
     *  @private
     */ 
    override protected function commitProperties():void
    {
        super.commitProperties();
        
        if (blendModeChanged)
        {
            blendModeChanged = false;
            super.blendMode = _blendMode;
        }
        
        if (needsDisplayObjectAssignment)
        {
            needsDisplayObjectAssignment = false;
            assignDisplayObjects();
        }
        
        if (scaleGridChanged)
        {
        	// Don't reset scaleGridChanged since we also check it in updateDisplayList
        	if (isValidScaleGrid())
        		resizeMode = ResizeMode.SCALE; // Force the resizeMode to scale	
        }
        
        // TODO EGeorgie: we need to optimize this, iterating through all the elements is slow.
        // Validate element properties
        if (numGraphicElements > 0)
        {
            var length:int = numElements;
            for (var i:int = 0; i < length; i++)
            {
                var element:IGraphicElement = getElementAt(i) as IGraphicElement;
                if (element)
                    element.validateProperties();
            }
        }
    }
    
    /**
     *  @private
     */
    override public function validateSize(recursive:Boolean = false):void
    {
        // Since IGraphicElement is not ILayoutManagerClient, we need to make sure we
        // validate sizes of the elements, even in cases where recursive==false.
        
        // TODO EGeorgie: we need to optimize this, iterating through all the elements is slow.
        // Validate element size
        if (numGraphicElements > 0)
        {
            var length:int = numElements;
            for (var i:int = 0; i < length; i++)
            {
                var element:IGraphicElement = getElementAt(i) as IGraphicElement;
                if (element)
                    element.validateSize();
            }
        }

        super.validateSize(recursive);
    }   
    
    /**
     *  @private
     */
    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {    	
        super.updateDisplayList(unscaledWidth, unscaledHeight);
        
        // Clear the group's graphic because graphic elements might be drawing to it
        // This isn't needed for DataGroup because there's no DisplayObject sharing
        var sharedDisplayObject:ISharedDisplayObject = this;
        if (sharedDisplayObject.redrawRequested)
            graphics.clear();
        
        // Iterate through the graphic elements. If an element has a displayObject that has been 
        // invalidated, then validate all graphic elements that draw to this displayObject. 
        // The algorithm assumes that all of the elements that share a displayObject are in between
        // the element with the shared displayObject and the next element that has a displayObject.
        if (numGraphicElements > 0)
        {
	        var length:int = numElements;
	        for (var i:int = 0; i < length; i++)
	        {
	            var element:IGraphicElement = getElementAt(i) as IGraphicElement;
	            if (!element)
	               continue;

	            // Do a special check for layer, we may stumble upon an element with layer != 0
	            // before we're done with the current shared sequence and we don't want to mark
	            // the sequence as valid, until we reach the next sequence.   
                if (element.layer == 0)
                {
                    // Is this the start of a new shared sequence?         	
	            	if (element.shareIndex <= 0)
	            	{
	            	    // We have finished redrawing the previous sequence
	            	    if (sharedDisplayObject)
	            	        sharedDisplayObject.redrawRequested = false;
	            	    
	            	    // Start the new sequence
                        sharedDisplayObject = element.displayObject as ISharedDisplayObject;
	            	}
	            	
	            	if (!sharedDisplayObject || sharedDisplayObject.redrawRequested) 
	            		element.validateDisplayList();
	            }
	            else
	            {
	                // If we have layering, we don't share the display objects.
	                // Don't update the current sharedDisplayObject 
	                var elementDisplayObject:ISharedDisplayObject = element.displayObject as ISharedDisplayObject;
	                if (!elementDisplayObject || elementDisplayObject.redrawRequested)
	                {
	                   element.validateDisplayList();

	                   if (elementDisplayObject)
                           elementDisplayObject.redrawRequested = false;
	                }
	            }
	        }
        }
	        
        // Mark the last shared displayObject valid
        if (sharedDisplayObject)
            sharedDisplayObject.redrawRequested = false;
        
        if (scaleGridChanged)
        {
        	scaleGridChanged = false;
        
        	if (isValidScaleGrid())
        	{
	        	if (numChildren > 0)
	        		throw new Error("ScaleGrid properties can not be set on this Group since at least one child element is a DisplayObject.");

	        	super.scale9Grid = new Rectangle(scaleGridLeft, 
	        							   scaleGridTop,	
	        							   scaleGridRight - scaleGridLeft, 
	        							   scaleGridBottom - scaleGridTop);
	        }
	        else
	        {
	        	super.scale9Grid = null;
	        }							   
        }
    }

    /**
     *  @private
     *  TODO: Most of this code is a duplicate of UIComponent::notifyStyleChangeInChildren,
     *  refactor as appropriate to avoid code duplication once we have a common
     *  child iterator between UIComponent and Group.
     */ 
    override public function notifyStyleChangeInChildren(
                        styleProp:String, recursive:Boolean):void
    {
        if (mxmlContentChanged || !recursive) 
            return;
            
        var n:int = numElements;
        for (var i:int = 0; i < n; i++)
        {
            var child:ISimpleStyleClient = getElementAt(i) as ISimpleStyleClient;
            if (child)
            {
                child.styleChanged(styleProp);
                
                if (child is IStyleClient)
                    IStyleClient(child).notifyStyleChangeInChildren(styleProp, recursive);
            }
        }
    }
    
    /**
     *  @private
     *  TODO: Most of this code is a duplicate of UIComponent::regenerateStyleCache,
     *  refactor as appropriate to avoid code duplication once we have a common
     *  child iterator between UIComponent and Group.
     */ 
    override public function regenerateStyleCache(recursive:Boolean):void
    {
        // Regenerate the proto chain for this object
        initProtoChain();

        // Recursively call this method on each child.
        var n:int = numElements;
        for (var i:int = 0; i < n; i++)
        {
            var child:IVisualElement = getElementAt(i);

            if ( recursive && child is IStyleClient)
            {
                // Does this object already have a proto chain?
                // If not, there's no need to regenerate a new one.
                if (IStyleClient(child).inheritingStyles !=
                    StyleProtoChain.STYLE_UNINITIALIZED)
                {
                    IStyleClient(child).regenerateStyleCache(recursive);
                }
            }
            else if (child is IUITextField)
            {
                // Does this object already have a proto chain?
                // If not, there's no need to regenerate a new one.
                if (IUITextField(child).inheritingStyles)
                    StyleProtoChain.initTextField(IUITextField(child));
            }
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Content management
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override public function get numElements():int
    {
        if (_mxmlContent == null)
            return 0;

        return _mxmlContent.length;
    }
    
    /**
     *  @private
     */ 
    override public function getElementAt(index:int):IVisualElement
    {
        // check for RangeError:
        checkForRangeError(index);
        
        return _mxmlContent[index];
    }
    
    /**
     *  @private 
     *  Checks the range of index to make sure it's valid
     */ 
    private function checkForRangeError(index:int, addingElement:Boolean = false):void
    {
        // figure out the maximum allowable index
        var maxIndex:int = (_mxmlContent == null ? -1 : _mxmlContent.length - 1);
        
        // if adding an element, we allow an extra index at the end
        if (addingElement)
            maxIndex++;
            
        if (index < 0 || index > maxIndex)
            throw new RangeError(resourceManager.getString("components", "indexOutOfRange", [index]));
    }
 
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function addElement(element:IVisualElement):IVisualElement
    {
        var index:int = numElements;
        
        // This handles the case where we call addElement on something
        // that already is in the list.  Let's just handle it silently
        // and not throw up any errors.
        if (element.parent == this)
            index = numElements-1;
        
        return addElementAt(element, index);
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function addElementAt(element:IVisualElement, index:int):IVisualElement
    {
        if (element == this)
            throw new ArgumentError(resourceManager.getString("components", "cannotAddYourselfAsYourChild"));
            
        // check for RangeError:
        checkForRangeError(index, true);
        
        var host:DisplayObject = element.parent; 
        
        // This handles the case where we call addElement on something
        // that already is in the list.  Let's just handle it silently
        // and not throw up any errors.
        if (host == this)
        {
            setElementIndex(element, index);
            return element;
        }
        else if (host is IVisualElementContainer)
        {
            // Remove the item from the group if that group isn't this group
            IVisualElementContainer(host).removeElement(element);
        }
        
        // If we don't have any content yet, initialize it to an empty array
        if (_mxmlContent == null)
            _mxmlContent = [];
        
        _mxmlContent.splice(index, 0, element);
        
        if (!mxmlContentChanged)
            elementAdded(element, index);
        
        scaleGridChanged = true;
                
        return element;
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function removeElement(element:IVisualElement):IVisualElement
    {
        return removeElementAt(getElementIndex(element));
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function removeElementAt(index:int):IVisualElement
    {
        // check RangeError
        checkForRangeError(index);
        
        var element:IVisualElement = _mxmlContent[index];
        
        // Need to call elementRemoved before removing the item so anyone listening
        // for the event can access the item.
        
        if (!mxmlContentChanged)
            elementRemoved(element, index);
        
        _mxmlContent.splice(index, 1);
        
        return element;
    }
        
    /**
     *  @inheritDoc
     */
    public function removeAllElements():void
    {
        for (var i:int = numElements - 1; i >= 0; i--)
        {
            removeElementAt(i);
        }
    }
    
    /**
     *  @private
     */ 
    override public function getElementIndex(element:IVisualElement):int
    {
        var index:int = _mxmlContent ? _mxmlContent.indexOf(element) : -1;
        
        if (index == -1)
            throw ArgumentError(resourceManager.getString("components", "elementNotFoundInGroup", [element]));
        else
            return index;
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function setElementIndex(element:IVisualElement, index:int):void
    {
        // check for RangeError...this is done in addItemAt
        // but we want to do it before removing the element
        checkForRangeError(index);
        
        removeElement(element);
        addElementAt(element, index);
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function swapElements(element1:IVisualElement, element2:IVisualElement):void
    {
        swapElementsAt(getElementIndex(element1), getElementIndex(element2));
    }
    
    /**
     *  @inheritDoc
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function swapElementsAt(index1:int, index2:int):void
    {
        // Make sure that index1 is the smaller index so that addElementAt 
        // doesn't RTE
        if (index1 > index2)
        {
            var temp:int = index2;
            index2 = index1;
            index1 = temp; 
        }
        else if (index1 == index2)
            return;
        
        var element1:IVisualElement = getElementAt(index1);
        var element2:IVisualElement = getElementAt(index2);
        
        removeElement(element1);
        removeElement(element2);
        
        addElementAt(element2, index1);
        addElementAt(element1, index2);
    }
    
    //--------------------------------------------------------------------------
    //
    //  Content management (internal)
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override public function invalidateLayering():void
    {
        if (layeringMode == ITEM_ORDERED_LAYERING)
            layeringMode = SPARSE_LAYERING;
        invalidateDisplayObjectOrdering();
    }

    /**
     *  Adds an item to this Group.
     *  Flex calls this method automatically; you do not call it directly.
     *
     *  @param item The item that was added.
     *
     *  @param index The index where the item was added.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    mx_internal function elementAdded(element:IVisualElement, index:int):void
    {
        var child:DisplayObject;
        
        if (layout)
            layout.elementAdded(index);        
                
        if (element.layer != 0)
            invalidateLayering();

        if (element is IGraphicElement) 
        {
            numGraphicElements++;
            addingGraphicElementChild(element as IGraphicElement);
            invalidateDisplayObjectOrdering();
        }   
        else
        {
            // item must be a DisplayObject
            
            // if the display object ordering is invalidated (because we have graphic elements 
            // that aren't actually in the display list), then lets just add our item to the end.  
            // If the ordering isn't invalidated, then let's just try to add it to the proper index.
            if (invalidateDisplayObjectOrdering())
            {
                // This always adds the child to the end of the display list. Any 
                // ordering discrepancies will be fixed up in assignDisplayObjects().
                child = addItemToDisplayList(DisplayObject(element), element);
            }
            else
            {
                child = addItemToDisplayList(DisplayObject(element), element, index);
            }
        }
        
        dispatchEvent(new ElementExistenceEvent(
                      ElementExistenceEvent.ELEMENT_ADD, false, false, element, index));
        
        invalidateSize();
        invalidateDisplayList();
    }
    
    /**
     *  Removes an item from this Group.
     *  Flex calls this method automatically; you do not call it directly.
     *
     *  @param index The index of the item that is being removed.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    mx_internal function elementRemoved(element:IVisualElement, index:int):void
    {
        var childDO:DisplayObject = element as DisplayObject;   
                
        dispatchEvent(new ElementExistenceEvent(
                      ElementExistenceEvent.ELEMENT_REMOVE, false, false, element, index));
        
        if (element && (element is IGraphicElement))
        {
            numGraphicElements--;
            removingGraphicElementChild(element as IGraphicElement);
        }
        else if (childDO && childDO.parent == this)
        {
            super.removeChild(childDO);
        }
        
        invalidateDisplayObjectOrdering();
        invalidateSize();
        invalidateDisplayList();

        if (layout)
            layout.elementRemoved(index);     
    }
    
    /**
     *  @private
     */
    mx_internal function addingGraphicElementChild(child:IGraphicElement):void
    {
        child.parentChanged(this);

        // Sets up the inheritingStyles and nonInheritingStyles objects
        // and their proto chains so that getStyle() works.
        // If this object already has some children,
        // then reinitialize the children's proto chains.
        if (child is IStyleClient)
            IStyleClient(child).regenerateStyleCache(true);
        
        if (child is ISimpleStyleClient)
            ISimpleStyleClient(child).styleChanged(null);

        if (child is IStyleClient)
            IStyleClient(child).notifyStyleChangeInChildren(null, true);

        // TODO EGeorgie: why do we need this here? We should not be hard-coding
        // against concrete GraphicElement types, maybe move this to a different
        // interface (IGraphicElement or IAdvancedStyleClient)?
        //
        // Inform the component that it's style properties
        // have been fully initialized. Most components won't care,
        // but some need to react to even this early change.
        if (child is TextGraphicElement)
            TextGraphicElement(child).stylesInitialized();
    }
    
    /**
     *  @private
     */
    mx_internal function removingGraphicElementChild(child:IGraphicElement):void
    {
        child.parentChanged(null);
        discardDisplayObject(child);        
    }

    /**
     *  Removes the element's <code>DisplayObject</code> from this <code>Group's</code>
     *  display list and sets the element's <code>displayObject</code> property to null.
     *
     *  The <code>Group</code> also ensures any elements that share the
     *  <code>DisplayObject</code> will be redrawn.
     * 
     *  <p>This method doesn't trigger new <code>DisplayObject</code> reassignment.
     *  To request new display object reassignment, call the
     *  <code>graphicElementLayerChanged</code> method.</p> 
     *
     *  @param element The graphic element whose display object will be discarded.
     *  @see #graphicElementLayerChanged
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function discardDisplayObject(element:IGraphicElement):void
    {
        var oldDisplayObject:DisplayObject = element.displayObject;
        element.displayObject = null;
        
        if (!oldDisplayObject)
            return;

        // If the element created the display object
        if (element.shareIndex <= 0)
        {
            super.removeChild(oldDisplayObject);

            // Redo the shared sequences. 
            invalidateDisplayObjectOrdering();
        }
        else if (oldDisplayObject is ISharedDisplayObject)
        {
            // Redraw the shared sequence
            ISharedDisplayObject(oldDisplayObject).redrawRequested = true;

            // Make sure we do a pass through the graphic elements and redraw
            // the invalid ones.  We should only redraw, no need to redo the layout.
            super.$invalidateDisplayList();
        }
    }
    
    /**
     *  @private
     *  
     *  Returns true if the Group's display object can be shared with graphic elements
     *  inside the group
     */
    private function get canShareDisplayObject():Boolean
    {
        // Work-around for Flash Player bug: if GraphicElements share
        // the Group's Display Object and cacheAsBitmap is true, the
        // scrollRect won't function correctly.
        // We can't even check the cacheAsBitmap property since that will
        // cause a back buffer allocation, which is another FP bug.
        if (scrollRect)
            return false;
 
        // we can't share ourselves if we're in blendMode != normal, or we have 
        // to deal with any layering.  The reason is because we handle layer = 0 first
        // in our implementation, and we don't want those to use our display object to 
        // draw into because there could be something further down the line that has 
        // layer < 0
        // Make sure we use _blendMode here, since _blendMode can be "normal", but
        // blendMode still report as "layer".
        return _blendMode == "normal" && (layeringMode == ITEM_ORDERED_LAYERING);
    }
    
    /**
     *  @private
     *  
     *  Invalidates the display object ordering and will run assignDisplayObjects()
     *  if necessary.
     * 
     *  @return true if the display object ordering needed to be invalidated; 
     *          false otherwise.
     */
    private function invalidateDisplayObjectOrdering():Boolean
    {
        if (layeringMode == SPARSE_LAYERING || numGraphicElements > 0)
        {
            needsDisplayObjectAssignment = true;
            invalidateProperties();
            return true;
        }
        
        return false;
    }
    
    
    /**
     *  @private
     *  
     *  Called to assign display objects to graphic elements
     */
    private function assignDisplayObjects():void
    {
        var topLayerItems:Vector.<IVisualElement>;
        var bottomLayerItems:Vector.<IVisualElement>;        
        var keepLayeringEnabled:Boolean = false;
        var insertIndex:int = 0;
        
        // Keep track of the previous IVisualElement.  This is used when
        // assigning DisplayObjects to the IGraphicElements.
        // If the Group can share its DisplayObject with the IGraphicElements
        // then initialize the prevItem with this Group object.
        var prevItem:IVisualElement;
        if (canShareDisplayObject)
            prevItem = this;
            
        // Iterate through all of the items
        var len:int = numElements; 
        for (var i:int = 0; i < len; i++)
        {  
            var item:IVisualElement = getElementAt(i);
            
            if (layeringMode != ITEM_ORDERED_LAYERING)
            {
                var layer:Number = item.layer;
                if (layer != 0)
                {               
                    if (layer > 0)
                    {
                        if (topLayerItems == null) topLayerItems = new Vector.<IVisualElement>();
                        topLayerItems.push(item);
                        continue;                   
                    }
                    else
                    {
                        if (bottomLayerItems == null) bottomLayerItems = new Vector.<IVisualElement>();
                        bottomLayerItems.push(item);
                        continue;                   
                    }
                }
            }
            
            // this should only get called if layer == 0, or we don't care
            // about layering (layeringMode == ITEM_ORDERED_LAYERING)
            insertIndex = assignDisplayObjectTo(item, prevItem, insertIndex);
            prevItem = item;
        }
        
        // we've done all layer == 0 items. 
        // now let's put the higher z-index ones on next
        // then we'll handle the ones on bottom, but we'll
        // insert them in the very beginning (index = 0)
        
        if (topLayerItems != null)
        {
            keepLayeringEnabled = true;
            //topLayerItems.sortOn("layer",Array.NUMERIC);
            GroupBase.mx_internal::sortOnLayer(topLayerItems);
            len = topLayerItems.length;
            for (i=0;i<len;i++)
            {
                // For layer != 0, we never share display objects
                insertIndex = assignDisplayObjectTo(topLayerItems[i], null /*prevElement*/, insertIndex);
            }
        }
        
        if (bottomLayerItems != null)
        {
            keepLayeringEnabled = true;
            insertIndex = 0;

            //bottomLayerItems.sortOn("layer",Array.NUMERIC);
            GroupBase.mx_internal::sortOnLayer(bottomLayerItems);
            len = bottomLayerItems.length;

            for (i=0;i<len;i++)
            {
                // For layer != 0, we never share dsiplay objects
                insertIndex = assignDisplayObjectTo(bottomLayerItems[i], null /*prevElement*/, insertIndex);
            }
        }
        
        // If we tried to layer these visual elements and found that we 
        // don't actually need to because layer=0 for all of them, 
        // then lets optimize this next time and just skip the layering step.
        // If an element gets added that has layer set to something non-zero, then 
        // layeringMode will get set to SPARSE_LAYERING.
        // If the layer property changes on a current element, invalidateLayering()
        // will be called and layeringMode will get set to SPARSE_LAYERING.
        if (keepLayeringEnabled == false)
            layeringMode = ITEM_ORDERED_LAYERING;
            
        // Make sure we do a pass through the graphic elements and redraw
        // the invalid ones.  We should only redraw, no need to redo the layout.
        super.$invalidateDisplayList();
    }
    
    /**
     *  @private
     *  Assigns a DisplayObject to the curElement and ensures the DisplayObject
     *  is at insertIndex in the display object list.
     * 
     *  If <code>curElement</code> implements IGraphicElement, then both its
     *  DisplayObject and shareIndex will be updated.
     * 
     *  @curElement The current element to assign DisplayObject to
     *  @prevEelement The previous element in the list of elements or null.
     *  @return Returns the display list index after the current element's
     *  DisplayObject.
     */
    private function assignDisplayObjectTo(curElement:IVisualElement,
                                           prevElement:IVisualElement,
                                           insertIndex:int):int
    {
        if (curElement is DisplayObject)
        {
            super.setChildIndex(curElement as DisplayObject, insertIndex++);
        }
        else if (curElement is IGraphicElement)
        {
            var current:IGraphicElement = IGraphicElement(curElement);
            var previous:IGraphicElement = prevElement as IGraphicElement;
            
            // Previous IGraphicElement can share with us if it's already sharing
            // the DisplayObject in a sequence, or if it can share its DisplayObject.
            var previousCanDrawToShared:Boolean = previous && !previous.closeSequence() &&
                (previous.shareIndex > 0 ||
                 (previous.displayObject is ISharedDisplayObject &&
                 previous.canDrawToShared(previous.displayObject)));

            // Can we share the display object of the previous IGraphicElement?
            if (previousCanDrawToShared && current.canDrawToShared(previous.displayObject))
            {
                // If we are the second element in the shared sequence,
                // make sure that the first element has the correct sharedIndex
                if (previous.shareIndex == -1)
                    previous.shareIndex = 0;

                setSharedDisplayObject(current, previous.shareIndex + 1, previous.displayObject);
            }
            else if (prevElement == this && current.canDrawToShared(this))
            {
                setSharedDisplayObject(current, 1, this);
            }
            else
            {
                // We don't want to create new DisplayObjects for elements that
                // already have created their own their display objects.
                var ownsDisplayObject:Boolean = current.shareIndex <= 0;

                // If the element doesn't have a DisplayObject or it doesn't own
                // the DisplayObject it currently has, then create a new one
                var displayObject:DisplayObject = current.displayObject;
                if (!ownsDisplayObject || !displayObject)
                    displayObject = current.createDisplayObject();

                // Make sure the DisplayObject is at the correct position.
                // Check displayObject for null, some graphic elements
                // may choose not to create a DisplayObject during this pass.
                if (displayObject)
                    addItemToDisplayList(displayObject, current, insertIndex++);

                setSharedDisplayObject(current, -1, displayObject);
            }
        }
        return insertIndex;
    }

    /**
     *  @private
     *  Assigns the specified shareIndex and displayObject to the element.
     *  Performs invalidation of the old and new shared sequenences.
     *  If necesary, removes the old display object from the list.
     *  Does not invalidate the Group's display list.
     */
    private function setSharedDisplayObject(element:IGraphicElement,
                                            shareIndex:int, 
                                            displayObject:DisplayObject):void
    {
        // Make sure we remove or mark for redraw the old displayObject
        var oldDisplayObject:DisplayObject = element.displayObject;
        var oldShareIndex:int = element.shareIndex;

        if (oldDisplayObject == displayObject && oldShareIndex == shareIndex)
            return;

        // Set the new index and DisplayObject
        element.shareIndex = shareIndex;
        element.displayObject = displayObject;

        // We don't care about changes from -1 to 0
        var shareIndexChanged:Boolean = (shareIndex != oldShareIndex && (oldShareIndex > 0 || shareIndex > 0 ));

        // Make sure we redraw the display object        
        if (shareIndexChanged || displayObject != oldDisplayObject)
        {
            if (displayObject is ISharedDisplayObject)
                ISharedDisplayObject(displayObject).redrawRequested = true;

            // Old display object also needs to be redrawn, in case any other GE still uses it.
            if (oldDisplayObject is ISharedDisplayObject)
                ISharedDisplayObject(oldDisplayObject).redrawRequested = true;
        }

        // Make sure we remove the old display object, if needed
        if (oldDisplayObject && oldDisplayObject != displayObject && oldShareIndex <= 0)
            super.removeChild(oldDisplayObject);
    }

    /**
     *  Remove an item from another group or display list
     *  before adding it to this display list.
     * 
     *  @param child DisplayObject to add to the display list.
     *
     *  @param item Item associated with the display object to be added.  If 
     *  the item itself is a display object, it will be the same as the child parameter.
     *
     *  @param index Index position where the display object is added.
     * 
     *  @return DisplayObject that was added.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */ 
    protected function addItemToDisplayList(child:DisplayObject, element:IVisualElement, index:int = -1):DisplayObject
    {
        // Calling removeElement should have already removed the child. This
        // should handle the case when we don't call removeItem
        if (child.parent)
        {
            if (child.parent == this)
            {
                var insertIndex:int;
                if (index == -1)
                    insertIndex = super.numChildren - 1;
                else if (index == 0)
                    insertIndex = 0;
                else
                    insertIndex = index;
                    
                super.setChildIndex(child, insertIndex);
                return child;
            }
        }
            
        return super.addChildAt(child, index != -1 ? index : super.numChildren);
    }
    
    /**
     *  Notify the host that an element has changed and needs to be redrawn.
     *  Group will call <code>validateDisplayList()</code> on the IGraphicElement
     *  to give it a chance to redraw.
     *
     *  @param element The element that has changed.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function graphicElementChanged(element:IGraphicElement):void
    {
        if (element.displayObject is ISharedDisplayObject)
            ISharedDisplayObject(element.displayObject).redrawRequested = true;

        // Invalidate display list only, no need to run the layout.
        super.$invalidateDisplayList();
    }
    
    /**
     *  Notify the host that an element has changed and needs to validate properties.
     *  Group will call <code>validateProperties()</code> on the IGraphicElement
     *  to give it a chnace to commit its properties.
     *
     *  @param element The element that has changed.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function graphicElementPropertiesChanged(element:IGraphicElement):void
    {
        invalidateProperties();        
    }

    /**
     *  Notify the host that an element size has changed.
     *  Group will call <code>validateSize()</code> on the IGraphicElement
     *  to give it a chance to validate its size.
     * 
     *  @param element The element that has changed size.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function graphicElementSizeChanged(element:IGraphicElement):void
    {
        // Invalidate the size only, no need to run the layout. 
        // Later on, if the size changes, then a layout pass will be triggered.
        super.$invalidateSize();
    }
    
    /**
     *  Notify the host that an element layer has changed.
     *  Group will re-evaluate the sequences of elements with shared DisplayObjects
     *  and may re-assign the DisplayObjects and redraw the sequences as a result. 
     * 
     *  @param element The element that has layers size.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function graphicElementLayerChanged(element:IGraphicElement):void
    {
        // One of our children have told us they might need a displayObject     
        invalidateDisplayObjectOrdering();
    }
    
    /**
     *  @private
     */
    override public function addChild(child:DisplayObject):DisplayObject
    {
        throw(new Error(resourceManager.getString("components", "addChildError")));
    }
    
    /**
     *  @private
     */
    override public function addChildAt(child:DisplayObject, index:int):DisplayObject
    {
        throw(new Error(resourceManager.getString("components", "addChildAtError")));
    }
    
    /**
     *  @private
     */
    override public function removeChild(child:DisplayObject):DisplayObject
    {
        throw(new Error(resourceManager.getString("components", "removeChildError")));
    }
    
    /**
     *  @private
     */
    override public function removeChildAt(index:int):DisplayObject
    {
        throw(new Error(resourceManager.getString("components", "removeChildAtError")));
    }
    
    /**
     *  @private
     */
    override public function setChildIndex(child:DisplayObject, index:int):void
    {
        throw(new Error(resourceManager.getString("components", "setChildIndexError")));
    }
    
    /**
     *  @private
     */
    override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
    {
        throw(new Error(resourceManager.getString("components", "swapChildrenError")));
    }
    
    /**
     *  @private
     */
    override public function swapChildrenAt(index1:int, index2:int):void
    {
        throw(new Error(resourceManager.getString("components", "swapChildrenAtError")));
    }
    
    //--------------------------------------------------------------------------
    //
    //  ISharedDisplayObject
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    private var _redrawRequested:Boolean = false;

    /**
     *  True when any of the <code>IGraphicElement</code> objects, that share
     *  this <code>DisplayObject</code>, needs to redraw.  This is used internally
     *  by the <code>Group</code> class and developers don't typically use this. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function get redrawRequested():Boolean
    {
        return _redrawRequested;
    }

    /**
     *  @private
     */
    public function set redrawRequested(value:Boolean):void
    {
        _redrawRequested = value;
    }
}
}
