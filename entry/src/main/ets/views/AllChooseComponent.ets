import TodoListModelView from '../viewModel/TodoListViewModel';


@Component
export struct AllChooseComponent {
  @State titleName: string = '全选';
  @Link todoListViewModel: TodoListModelView;

  build() {
    Row() {
      Button(`${this.titleName}`, {type: ButtonType.Capsule})
        .onClick(() => {
          this.todoListViewModel.chooseAll();
          this.titleName = this.todoListViewModel.isChoosen ? '全选' : '取消全选';
        })
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#f7f6cc74')
    }
    .padding({left: this.todoListViewModel.isChoosen? 15: 0})
    .width('100%')
    .margin({top: 10, bottom: 10})
  }

}