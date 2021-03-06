/* Copyright (c) 2013 Jin Li, http://www.luvfight.me

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#ifndef __DOROTHY_PLATFORM_OPROPERTY_H__
#define __DOROTHY_PLATFORM_OPROPERTY_H__

NS_DOROTHY_PLATFORM_BEGIN

class oUnit;

typedef Delegate<void (oUnit* owner, float oldValue, float newValue)> oPropertyHandler;

class oProperty
{
public:
	explicit oProperty(oUnit* owner, float data = 0.0f);
	oProperty(const oProperty& prop);
	oUnit* getOwner() const;
	/** Change its value and not let others know. */
	void reset(float value);
	void operator=(float value);
	void operator+=(float value);
	void operator-=(float value);
	void operator=(const oProperty& prop);
	void operator+=(const oProperty& prop);
	void operator-=(const oProperty& prop);
	bool operator==(const oProperty& prop);
	bool operator!=(const oProperty& prop);
	operator float() const;
	/** Change its value and notice others. */
	oPropertyHandler changed;
private:
	oUnit* _owner;
	float _data;
};

NS_DOROTHY_PLATFORM_END

#endif // __DOROTHY_PLATFORM_OPROPERTY_H__