## 学习开发笔记

## 一、UI范式

### 基本语法

#### 装饰器：

- @Entry
- @Component
- @State

- @Builder/@BuilderParam：特殊的封装UI描述的方法，细粒度的封装和复用UI描述。
- @Extend/@Styles：扩展系统组件和封装属性样式，更灵活地组合系统组件。

#### 配置事件

事件方法以“.”链式调用的方式配置系统组件支持的事件，建议每个事件方法单独写一行。

使用组件的成员函数配置组件的事件方法，需要bind this。ArkTS语法不建议使用成员函数配合bind this来配置组件的事件方法。

```typescript
myClickHandler(): void {
  this.counter += 2;
}
...
Button('add counter')
  .onClick(this.myClickHandler.bind(this))
```

使用声明的箭头函数时可以直接调用，不需要bind this。

```typescript
fn = () => {  
    console.info(`counter: ${this.counter}`) 
    this.counter++
}
...
Button('add counter')
    .onClick(this.fn)
```

#### 自定义组件

```typescript
@Component
struct HelloComponent {
  @State message: string = 'Hello, World!';

  build() {
    // HelloComponent自定义组件组合系统组件Row和Text
    Row() {
      Text(this.message)
        .onClick(() => {
          // 状态变量message的改变驱动UI刷新，UI从'Hello, World!'刷新为'Hello, ArkUI!'
          this.message = 'Hello, ArkUI!';
        })
    }
  }
}
```

> 如果在其他文件中引用自定义组件，需要使用export关键字导出组件，并在使用的页面import该自定义组件。

@Entry装饰的自定义组件将作为UI页面的入口。在单个UI页面中，仅允许存在一个由@Entry装饰的自定义组件作为页面的入口。@Entry可以接受一个可选的LocalStorage的参数。