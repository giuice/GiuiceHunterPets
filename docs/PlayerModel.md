# Player Model uiobject 

## Example
```lua
local m = CreateFrame("PlayerModel", nil, UIParent)
m:SetPoint("CENTER")
m:SetSize(256, 256)
m:SetDisplayInfo(21723) -- creature/murloccostume/murloccostume.m2
```

## Methods
PlayerModel:ApplySpellVisualKit(spellVisualKitID [, oneShot])
PlayerModel:CanSetUnit(unit)
PlayerModel:FreezeAnimation(anim, variation, frame) - Freezes an animation at a specific animation frame on the model.
PlayerModel:GetDisplayInfo() : displayID
PlayerModel:GetDoBlend() : doBlend
PlayerModel:GetKeepModelOnHide() : keepModelOnHide
PlayerModel:HasAnimation(anim) : hasAnimation - Returns true if the currently displayed model supports the given animation ID.
PlayerModel:PlayAnimKit(animKit [, loop])
PlayerModel:RefreshCamera()
PlayerModel:RefreshUnit()
PlayerModel:SetAnimation(anim [, variation]) - Sets the animation to be played by the model.
PlayerModel:SetBarberShopAlternateForm()
PlayerModel:SetCamDistanceScale(scale)
PlayerModel:SetCreature(creatureID [, displayID])
PlayerModel:SetDisplayInfo(displayID [, mountDisplayID])
PlayerModel:SetDoBlend([doBlend])
PlayerModel:SetItem(itemID [, appearanceModID, itemVisualID])
PlayerModel:SetItemAppearance(itemAppearanceID [, itemVisualID, itemSubclass])
PlayerModel:SetKeepModelOnHide(keepModelOnHide)
PlayerModel:SetPortraitZoom(zoom)
PlayerModel:SetRotation(radians [, animate])
PlayerModel:SetUnit(unit [, blend, useNativeForm]) : success - Sets the model to display the specified unit.
PlayerModel:StopAnimKit()
PlayerModel:ZeroCachedCenterXY()
Model:AdvanceTime()
Model:ClearFog()
Model:ClearModel()
Model:ClearTransform()
Model:GetCameraDistance() : distance
Model:GetCameraFacing() : radians
Model:GetCameraPosition() : positionX, positionY, positionZ
Model:GetCameraRoll() : radians
Model:GetCameraTarget() : targetX, targetY, targetZ
Model:GetDesaturation() : strength
Model:GetFacing() : facing - Returns the offset of the rotation angle.
Model:GetFogColor() : colorR, colorG, colorB, colorA
Model:GetFogFar() : fogFar
Model:GetFogNear() : fogNear
Model:GetLight() : enabled, light
Model:GetModelAlpha() : alpha
Model:GetModelDrawLayer() : layer, sublayer
Model:GetModelFileID() : modelFileID - Returns the file ID associated with the currently displayed model.
Model:GetModelScale() : scale
Model:GetPaused() : paused
Model:GetPitch() : pitch
Model:GetPosition() : positionX, positionY, positionZ
Model:GetRoll() : roll
Model:GetShadowEffect() : strength
Model:GetViewInsets() : left, right, top, bottom
Model:GetViewTranslation() : x, y
Model:GetWorldScale() : worldScale
Model:HasAttachmentPoints() : hasAttachmentPoints
Model:HasCustomCamera() : hasCustomCamera
Model:IsUsingModelCenterToTransform() : useCenter
Model:MakeCurrentCameraCustom()
Model:ReplaceIconTexture(asset)
Model:SetCamera(cameraIndex) - Selects a predefined camera.
Model:SetCameraDistance(distance)
Model:SetCameraFacing(radians)
Model:SetCameraPosition(positionX, positionY, positionZ)
Model:SetCameraRoll(radians)
Model:SetCameraTarget(targetX, targetY, targetZ)
Model:SetCustomCamera(cameraIndex)
Model:SetDesaturation(strength)
Model:SetFacing(facing) - Rotates the displayed model for the given angle in counter-clockwise direction.
Model:SetFogColor(colorR, colorG, colorB [, a]) - Sets the color used for the fogging in the model frame.
Model:SetFogFar(fogFar) - Sets the far clipping plane for fogging.
Model:SetFogNear(fogNear) - Sets the near clipping plane for fogging.
Model:SetGlow(glow)
Model:SetLight(enabled, light) - Specifies model lighting.
Model:SetModel(asset [, noMip]) - Sets the model to display a certain mesh.
Model:SetModelAlpha(alpha)
Model:SetModelDrawLayer(layer)
Model:SetModelScale(scale)
Model:SetParticlesEnabled(enabled)
Model:SetPaused(paused)
Model:SetPitch(pitch)
Model:SetPosition(positionX, positionY, positionZ) - Positions a model relative to the bottom-left corner.
Model:SetRoll(roll)
Model:SetSequence(sequence) - Sets the animation-sequence to be played.
Model:SetSequenceTime(sequence, timeOffset)
Model:SetShadowEffect(strength)
Model:SetTransform([translation, rotation, scale])
Model:SetViewInsets(left, right, top, bottom)
Model:SetViewTranslation(x, y)
Model:TransformCameraSpaceToModelSpace(cameraPosition) : modelPosition
Model:UseModelCenterToTransform(useCenter)
## Collapse
Frame:AbortDrag()
Frame:CanChangeAttribute() : canChangeAttributes
Frame:CreateFontString([name, drawLayer, templateName]) : line - Creates a fontstring.
Frame:CreateLine([name, drawLayer, templateName, subLevel]) : line - Draws a line.
Frame:CreateMaskTexture([name, drawLayer, templateName, subLevel]) : maskTexture - Creates a mask texture.
Frame:CreateTexture([name, drawLayer, templateName, subLevel]) : texture - Creates a texture.
Frame:DesaturateHierarchy(desaturation [, excludeRoot])
Frame:DisableDrawLayer(layer) - Prevents display of the frame on the specified draw layer.
Frame:DoesClipChildren() : clipsChildren
Frame:EnableDrawLayer(layer) - Allows display of the frame on the specified draw layer.
Frame:EnableGamePadButton([enable]) - Allows the receipt of gamepad button inputs for this frame.
Frame:EnableGamePadStick([enable]) - Allows the receipt of gamepad stick inputs for this frame.
Frame:EnableKeyboard([enable]) - Allows this frame to receive keyboard input.
Frame:ExecuteAttribute(attributeName, unpackedPrimitiveType, ...) : success, unpackedPrimitiveType, ...
Frame:GetAlpha() : alpha -> Region:GetAlpha
Frame:GetAttribute(attributeName) : value - Returns the value of a secure frame attribute.
Frame:GetBoundsRect() : left, bottom, width, height - Returns the calculated bounding box of the frame and all of its descendant regions.
Frame:GetChildren() : child1, ... - Returns a list of child frames belonging to the frame.
Frame:GetClampRectInsets() : left, right, top, bottom - Returns the frame's clamp rectangle offsets.
Frame:GetDontSavePosition() : dontSave
Frame:GetEffectiveAlpha() : effectiveAlpha - Returns the effective alpha after propagating from the parent region.
Frame:GetEffectivelyFlattensRenderLayers() : flatten - Returns true if render layer flattening has been implicitly enabled.
Frame:GetEffectiveScale() : effectiveScale - Returns the effective scale after propagating from the parent region.
Frame:GetFlattensRenderLayers() : flatten - Returns true if render layer flattening has been enabled.
Frame:GetFrameLevel() : frameLevel - Returns the frame level of the frame.
Frame:GetFrameStrata() : strata - Returns the layering strata of the frame.
Frame:GetHitRectInsets() : left, right, top, bottom - Returns the insets of the frame's hit rectangle.
Frame:GetHyperlinksEnabled() : enabled - Returns true if mouse interaction with hyperlinks on the frame is enabled.
Frame:GetID() : id - Returns the frame's numeric identifier.
Frame:GetNumChildren() : numChildren - Returns the number of child frames belonging to the frame.
Frame:GetNumRegions() : numRegions - Returns the number of non-Frame child regions belonging to the frame.
Frame:GetPropagateKeyboardInput() : propagate - Returns whether the frame propagates keyboard events.
Frame:GetRaisedFrameLevel() : frameLevel
Frame:GetRegions() : region1, ... - Returns a list of non-Frame child regions belonging to the frame.
Frame:GetResizeBounds() : minWidth, minHeight, maxWidth, maxHeight - Returns the minimum and maximum size of the frame for user resizing.
Frame:GetScale() : frameScale -> Region:GetScale
Frame:GetWindow() : window
Frame:HasFixedFrameLevel() : isFixed
Frame:HasFixedFrameStrata() : isFixed
Frame:Hide() -> ScriptRegion:Hide
Frame:InterceptStartDrag(delegate)
Frame:IsClampedToScreen() : clampedToScreen - Returns whether a frame is prevented from being moved off-screen.
Frame:IsEventRegistered(eventName) : isRegistered, unit1, ... - Returns whether a frame is registered to an event.
Frame:IsGamePadButtonEnabled() : enabled - Checks if this frame is configured to receive gamepad button inputs.
Frame:IsGamePadStickEnabled() : enabled - Checks if this frame is configured to receive gamepad stick inputs.
Frame:IsIgnoringParentAlpha() : ignore -> Region:IsIgnoringParentAlpha
Frame:IsIgnoringParentScale() : ignore -> Region:IsIgnoringParentScale
Frame:IsKeyboardEnabled() : enabled - Returns true if keyboard interactivity is enabled for the frame.
Frame:IsMovable() : isMovable - Returns true if the frame is movable.
Frame:IsObjectLoaded() : isLoaded -> Region:IsObjectLoaded
Frame:IsResizable() : resizable - Returns true if the frame can be resized by the user.
Frame:IsShown() : isShown -> ScriptRegion:IsShown
Frame:IsToplevel() : isTopLevel - Returns whether this frame should raise its frame level on mouse interaction.
Frame:IsUserPlaced() : isUserPlaced - Returns whether the frame has been moved by the user.
Frame:IsUsingParentLevel() : usingParentLevel
Frame:IsVisible() : isVisible -> ScriptRegion:IsVisible
Frame:LockHighlight() - Sets the frame or button to always be drawn highlighted.
Frame:Lower() - Reduces the frame's frame level below all other frames in its strata.
Frame:Raise() - Increases the frame's frame level above all other frames in its strata.
Frame:RegisterAllEvents() - Flags the frame to receive all events.
Frame:RegisterEvent(eventName) : registered - Registers the frame to an event.
Frame:RegisterForDrag([button1, ...]) - Registers the frame for dragging with a mouse button.
Frame:RegisterUnitEvent(eventName [, unit1, ...]) : registered - Registers the frame for a specific event, triggering only for the specified units.
Frame:RotateTextures(radians [, x, y])
Frame:SetAlpha(alpha) -> Region:SetAlpha
Frame:SetAttribute(attributeName, value) - Sets an attribute on the frame.
Frame:SetAttributeNoHandler(attributeName, value) - Sets an attribute on the frame without triggering the OnAttributeChanged script handler.
Frame:SetClampedToScreen(clampedToScreen) - Prevents the frame from moving off-screen.
Frame:SetClampRectInsets(left, right, top, bottom) - Controls how much of the frame may be moved off-screen.
Frame:SetClipsChildren(clipsChildren)
Frame:SetDontSavePosition(dontSave)
Frame:SetDrawLayerEnabled(layer [, isEnabled])
Frame:SetFixedFrameLevel(isFixed)
Frame:SetFixedFrameStrata(isFixed)
Frame:SetFlattensRenderLayers(flatten) - Controls whether all subregions are composited into a single render layer.
Frame:SetFrameLevel(frameLevel) - Sets the level at which the frame is layered relative to others in its strata.
Frame:SetFrameStrata(strata) - Sets the layering strata of the frame.
Frame:SetHighlightLocked(locked)
Frame:SetHitRectInsets(left, right, top, bottom) #secureframe - Returns the insets of the frame's hit rectangle.
Frame:SetHyperlinksEnabled([enabled]) - Allows mouse interaction with hyperlinks on the frame.
Frame:SetID(id) - Returns the frame's numeric identifier.
Frame:SetIgnoreParentAlpha(ignore) -> Region:SetIgnoreParentAlpha
Frame:SetIgnoreParentScale(ignore) -> Region:SetIgnoreParentScale
Frame:SetIsFrameBuffer(isFrameBuffer) - Controls whether or not a frame is rendered to its own framebuffer prior to being composited atop the UI.
Frame:SetMovable(movable) - Sets whether the frame can be moved.
Frame:SetPropagateKeyboardInput(propagate) #nocombat - Sets whether keyboard input is consumed by this frame or propagates to further frames.
Frame:SetResizable(resizable) - Sets whether the frame can be resized by the user.
Frame:SetResizeBounds(minWidth, minHeight [, maxWidth, maxHeight]) - Sets the minimum and maximum size of the frame for user resizing.
Frame:SetScale(scale) -> Region:SetScale
Frame:SetShown([shown]) -> ScriptRegion:SetShown
Frame:SetToplevel(topLevel) #secureframe - Controls whether or not a frame should raise its frame level on mouse interaction.
Frame:SetUserPlaced(userPlaced) - Sets whether a frame has been moved by the user and will be saved in the layout cache.
Frame:SetUsingParentLevel(usingParentLevel)
Frame:SetWindow([window])
Frame:Show() -> ScriptRegion:Show
Frame:StartMoving([alwaysStartFromMouse]) - Begins repositioning the frame via mouse movement.
Frame:StartSizing([resizePoint, alwaysStartFromMouse]) - Begins resizing the frame via mouse movement.
Frame:StopMovingOrSizing() - Stops moving or resizing the frame.
Frame:UnlockHighlight() - Sets the frame or button to not always be drawn highlighted.
Frame:UnregisterAllEvents() - Unregisters all events from the frame.
Frame:UnregisterEvent(eventName) : registered - Unregisters an event from the frame.
Region:GetAlpha() : alpha - Returns the region's opacity.
Region:GetDrawLayer() : layer, sublayer - Returns the layer in which the region is drawn.
Region:GetEffectiveScale() : effectiveScale - Returns the scale of the region after propagating from its parents.
Region:GetScale() : scale - Returns the scale of the region.
Region:GetVertexColor() : colorR, colorG, colorB, colorA - Returns the vertex color shading of the region.
Region:IsIgnoringParentAlpha() : isIgnoring - Returns true if the region is ignoring parent alpha.
Region:IsIgnoringParentScale() : isIgnoring - Returns true if the region is ignoring parent scale.
Region:IsObjectLoaded() : isLoaded - Returns true if the region is fully loaded.
Region:SetAlpha(alpha) - Sets the opacity of the region.
Region:SetDrawLayer(layer [, sublevel]) - Sets the layer in which the region is drawn.
Region:SetIgnoreParentAlpha(ignore) - Sets whether the region should ignore its parent's alpha.
Region:SetIgnoreParentScale(ignore) - Sets whether the region should ignore its parent's scale.
Region:SetScale(scale) - Sets the size scaling of the region.
Region:SetVertexColor(colorR, colorG, colorB [, a]) - Sets the vertex shading color of the region.
ScriptRegion:CanChangeProtectedState() : canChange - Returns true if protected properties of the region can be changed by non-secure scripts.
ScriptRegion:CollapsesLayout() : collapsesLayout
ScriptRegion:EnableMouse([enable]) - Sets whether the region should receive mouse input.
ScriptRegion:EnableMouseMotion([enable]) - Sets whether the region should receive mouse hover events.
ScriptRegion:EnableMouseWheel([enable]) - Sets whether the region should receive mouse wheel input.
ScriptRegion:GetBottom() : bottom #restrictedframe - Returns the offset to the bottom edge of the region.
ScriptRegion:GetCenter() : x, y #restrictedframe - Returns the offset to the center of the region.
ScriptRegion:GetHeight([ignoreRect]) : height - Returns the height of the region.
ScriptRegion:GetLeft() : left #restrictedframe - Returns the offset to the left edge of the region.
ScriptRegion:GetRect() : left, bottom, width, height #restrictedframe - Returns the coords and size of the region.
ScriptRegion:GetRight() : right #restrictedframe - Returns the offset to the right edge of the region.
ScriptRegion:GetScaledRect() : left, bottom, width, height - Returns the scaled coords and size of the region.
ScriptRegion:GetSize([ignoreRect]) : width, height - Returns the width and height of the region.
ScriptRegion:GetSourceLocation() : location - Returns the script name and line number where the region was created.
ScriptRegion:GetTop() : top #restrictedframe - Returns the offset to the top edge of the region.
ScriptRegion:GetWidth([ignoreRect]) : width - Returns the width of the region.
ScriptRegion:Hide() #secureframe - Hides the region.
ScriptRegion:IsCollapsed() : isCollapsed
ScriptRegion:SetCollapsesLayout(collapsesLayout)
ScriptRegion:IsAnchoringRestricted() : isRestricted - Returns true if the region has cross-region anchoring restrictions applied.
ScriptRegion:IsDragging() : isDragging - Returns true if the region is being dragged.
ScriptRegion:IsMouseClickEnabled() : enabled - Returns true if the region can receive mouse clicks.
ScriptRegion:IsMouseEnabled() : enabled - Returns true if the region can receive mouse input.
ScriptRegion:IsMouseMotionEnabled() : enabled - Returns true if the region can receive mouse hover events.
ScriptRegion:IsMouseMotionFocus() : isMouseMotionFocus - Returns true if the mouse cursor is hovering over the region.
ScriptRegion:IsMouseOver([offsetTop, offsetBottom, offsetLeft, offsetRight]) : isMouseOver - Returns true if the mouse cursor is hovering over the region.
ScriptRegion:IsMouseWheelEnabled() : enabled - Returns true if the region can receive mouse wheel input.
ScriptRegion:IsProtected() : isProtected, isProtectedExplicitly - Returns whether the region is currently protected.
ScriptRegion:IsRectValid() : isValid - Returns true if the region can be positioned on the screen.
ScriptRegion:IsShown() : isShown - Returns true if the region should be shown; it depends on the parents if it's visible.
ScriptRegion:IsVisible() : isVisible - Returns true if the region and its parents are shown.
ScriptRegion:SetMouseClickEnabled([enabled]) - Sets whether the region should receive mouse clicks.
ScriptRegion:SetMouseMotionEnabled([enabled]) - Sets whether the region should receive mouse hover events.
ScriptRegion:SetParent([parent]) - Sets the parent of the region.
ScriptRegion:SetPassThroughButtons([button1, ...]) #nocombat - Allows the region to propagate mouse clicks to underlying regions or the world frame.
ScriptRegion:SetPropagateMouseClicks(propagate)
ScriptRegion:SetPropagateMouseMotion(propagate)
ScriptRegion:SetShown([show]) #secureframe - Shows or hides the region.
ScriptRegion:Show() #secureframe - Shows the region.
ScriptRegionResizing:AdjustPointsOffset(x, y) #secureframe - Adjusts the x and y offset of the region.
ScriptRegionResizing:ClearAllPoints() - Removes all anchor points from the region.
ScriptRegionResizing:ClearPoint(point) - Removes an anchor point from the region by name.
ScriptRegionResizing:ClearPointsOffset() #secureframe - Resets the x and y offset on the region to zero.
ScriptRegionResizing:GetNumPoints() : numPoints - Returns the number of anchor points for the region.
ScriptRegionResizing:GetPoint([anchorIndex [, resolveCollapsed]]]) : point, relativeTo, relativePoint, offsetX, offsetY #restrictedframe - Returns an anchor point for ## the region.
ScriptRegionResizing:GetPointByName(point [, resolveCollapsed]) : point, relativeTo, relativePoint, offsetX, offsetY - Returns an anchor point by name for the region.
ScriptRegionResizing:SetAllPoints(relativeTo [, doResize]) - Positions the region the same as another region.
ScriptRegionResizing:SetHeight(height) - Sets the height of the region.
ScriptRegionResizing:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) #anchorfamily - Sets an anchor point for the region.
ScriptRegionResizing:SetSize(x, y) - Sets the width and height of the region.
ScriptRegionResizing:SetWidth(width) - Sets the width of the region.
AnimatableObject:CreateAnimationGroup([name, templateName]) : group - Creates an animation group.
AnimatableObject:GetAnimationGroups() : scriptObject, ... - Returns the animation groups of this region.
AnimatableObject:StopAnimating() - Stops any active animations on this region.
ScriptObject:GetScript(scriptTypeName [, bindingType]) : script - Returns the widget script handler.
ScriptObject:HasScript(scriptName) : hasScript - Returns true if the region supports the given script type.
ScriptObject:HookScript(scriptTypeName, script [, bindingType]) - Securely post-hooks a widget script handler.
ScriptObject:SetScript(scriptTypeName [, script]) - Sets the widget script handler.
Object:ClearParentKey() - Clears the parent key.
Object:GetDebugName([preferParentKey]) : debugName - Returns the object's debug name.
Object:GetParent() : parent - Returns the parent object.
Object:GetParentKey() : parentKey - Returns the key on the parent that references this object.
Object:SetParentKey(parentKey [, clearOtherKeys]) - Sets a key on the parent to the child object.
FrameScriptObject:GetName() : name - Returns the object's global name.
FrameScriptObject:GetObjectType() : objectType - Returns the object's widget type.
FrameScriptObject:IsForbidden() : isForbidden - Returns true if insecure interaction with the object is forbidden.
FrameScriptObject:IsObjectType(objectType) : isType - Returns true if the object belongs to a given widget type or its subtypes.
FrameScriptObject:SetForbidden() #protected - Sets the object to be forbidden from an insecure execution path.
Script Types
OnAnimFinished(self) - Invoked when the model's animation finishes.
OnAnimStarted(self) - Invoked when the model's animation starts.
OnModelLoaded(self) - Invoked when the model is loaded.
OnAttributeChanged(self, key, value) - Invoked when a secure frame attribute is changed.
OnChar(self, text) - Invoked for each text character typed in the frame.
OnDisable(self) - Invoked when the frame is disabled.
OnDragStart(self, button) - Invoked when the mouse is dragged starting in the frame
OnDragStop(self) - Invoked when the mouse button is released after a drag started in the frame,
OnEnable(self) - Invoked when the frame is enabled.
OnEvent(self, event, ...) - Invoked whenever an event fires for which the frame is registered.
OnGamePadButtonDown(self, button) - Invoked when a gamepad button is pressed.
OnGamePadButtonUp(self, button) - Invoked when a gamepad button is released.
OnGamePadStick(self, stick, x, y, len) - Invoked when a gamepad stick is moved.
OnHyperlinkClick(self, link, text, button, region, left, bottom, width, height) - Invoked when the mouse clicks a hyperlink on the FontInstance object.
OnHyperlinkEnter(self, link, text, region, left, bottom, width, height) - Invoked when the mouse moves over a hyperlink on the FontInstance object.
OnHyperlinkLeave(self) - Invoked when the mouse moves away from a hyperlink on the FontInstance object.
OnKeyDown(self, key) - Invoked when a keyboard key is pressed if the frame is keyboard enabled.
OnKeyUp(self, key) - Invoked when a keyboard key is released if the frame is keyboard enabled.
OnReceiveDrag(self) - Invoked when the mouse button is released after dragging into the frame.
OnSizeChanged(self, width, height) - Invoked when a frame's size changes.
OnUpdate(self, elapsed) - Invoked on every frame.
OnShow(self) - Invoked when the widget is shown.
OnHide(self) - Invoked when the widget is hidden.
OnEnter(self, motion) - Invoked when the cursor enters the widget's interactive area.
OnLeave(self, motion) - Invoked when the mouse cursor leaves the widget's interactive area.
OnMouseDown(self, button) - Invoked when a mouse button is pressed while the cursor is over the widget.
OnMouseUp(self, button, upInside) - Invoked when the mouse button is released following a mouse down action in the widget.
OnMouseWheel(self, delta) - Invoked when the widget receives a mouse wheel scrolling action.
OnLoad(self) - Invoked when the widget is created.