import ThingViewModel  from "../viewModel/ThingViewModel";
import { ThingViewModelArray } from "../viewModel/TodoListViewModel"
import { ThingComponent } from "./ThingComponent";

@Component
export struct TodoListComponent {
  @ObjectLink thingViewModelArray: ThingViewModelArray;

  build() {
    Column() {
      List() {
        ForEach(this.thingViewModelArray, (item: ThingViewModel) => {
          ListItem() {
            ThingComponent({thing: item})
              .margin(5)
          }
        }, (item: ThingViewModel) => {
          return item.thingName;
        })
      }
    }
  }
}